import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/velora.dart' hide FormData;
import 'package:velora_offline/velora_offline.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  group('ConnectivityService', () {
    test('reflects initial state and updates on stream events', () async {
      final source = ToggleConnectivitySource(online: true);
      final service = await ConnectivityService(source).init();

      expect(service.isOnline.value, isTrue);

      source.setOnline(false);
      await Future<void>.delayed(Duration.zero);
      expect(service.isOnline.value, isFalse);

      source.setOnline(true);
      await Future<void>.delayed(Duration.zero);
      expect(service.isOnline.value, isTrue);

      service.onClose();
    });

    test('fires onOnline callbacks only on offline -> online transition', () async {
      final source = ToggleConnectivitySource(online: false);
      final service = await ConnectivityService(source).init();

      var calls = 0;
      service.onOnline(() async {
        calls += 1;
      });

      // Already offline -> offline is not a transition (and setOnline is a
      // no-op here since the value isn't actually changing).
      source.setOnline(false);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 0);

      source.setOnline(true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);

      // online -> online is not a transition (and setOnline is a no-op).
      source.setOnline(true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);

      service.onClose();
    });
  });

  group('OfflineRequestQueue', () {
    test('enqueue persists and survives reload via a fresh queue', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await VeloraStorageService().init();
      final api = await _apiService((_) => _jsonResponse(200, {'success': true}));

      final queue = await OfflineRequestQueue(storage: storage, api: api).load();
      await queue.enqueue(
        OfflineRequest(
          id: '1',
          method: 'POST',
          path: '/notes',
          data: {'title': 'Buy milk'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      expect(queue.pending, hasLength(1));

      // A fresh queue instance over the same (mocked) SharedPreferences
      // storage should restore the persisted item.
      final reloaded = await OfflineRequestQueue(storage: storage, api: api).load();
      expect(reloaded.pending, hasLength(1));
      expect(reloaded.pending.single.path, '/notes');
      expect(reloaded.pending.single.data, {'title': 'Buy milk'});
    });

    test('flush replays queued writes and empties the queue on success', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await VeloraStorageService().init();
      final receivedPaths = <String>[];
      final api = await _apiService((options) {
        receivedPaths.add(options.path);
        return _jsonResponse(200, {'success': true});
      });

      final queue = await OfflineRequestQueue(storage: storage, api: api).load();
      await queue.enqueue(
        OfflineRequest(
          id: '1',
          method: 'POST',
          path: '/notes',
          data: {'title': 'first'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await queue.enqueue(
        OfflineRequest(
          id: '2',
          method: 'PUT',
          path: '/notes/1',
          data: {'title': 'second'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await queue.flush();

      expect(receivedPaths, ['/notes', '/notes/1']);
      expect(queue.pending, isEmpty);
      // Persisted state reflects the empty queue too.
      final reloaded = await OfflineRequestQueue(storage: storage, api: api).load();
      expect(reloaded.pending, isEmpty);
    });

    test('flush keeps items when the API call fails', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await VeloraStorageService().init();
      final api = await _apiService(
        (_) => ResponseBody.fromString('Server exploded', 500),
      );

      final queue = await OfflineRequestQueue(storage: storage, api: api).load();
      await queue.enqueue(
        OfflineRequest(
          id: '1',
          method: 'POST',
          path: '/notes',
          data: {'title': 'first'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await queue.flush();

      expect(queue.pending, hasLength(1));
    });

    test(
      'flush discards a 4xx (poison-pill) request and replays the rest',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = await VeloraStorageService().init();
        final receivedPaths = <String>[];
        final api = await _apiService((options) {
          receivedPaths.add(options.path);
          if (options.path == '/notes/bad') {
            return _jsonResponse(422, {'message': 'Validation failed'});
          }
          return _jsonResponse(200, {'success': true});
        });

        final queue = await OfflineRequestQueue(storage: storage, api: api).load();
        await queue.enqueue(
          OfflineRequest(
            id: '1',
            method: 'POST',
            path: '/notes/bad',
            data: {'title': 'first'},
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await queue.enqueue(
          OfflineRequest(
            id: '2',
            method: 'PUT',
            path: '/notes/1',
            data: {'title': 'second'},
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        await queue.flush();

        expect(receivedPaths, ['/notes/bad', '/notes/1']);
        expect(queue.pending, isEmpty);
        final reloaded = await OfflineRequestQueue(storage: storage, api: api).load();
        expect(reloaded.pending, isEmpty);
      },
    );

    test(
      'flush keeps a request on transient 408/429 but discards a 400',
      () async {
        final receivedPaths = <String>[];
        final statusCodes = <String, int>{
          '/notes/timeout': 408,
          '/notes/rate-limited': 429,
          '/notes/bad': 400,
        };
        final api = await _apiService((options) {
          receivedPaths.add(options.path);
          final statusCode = statusCodes[options.path]!;
          return _jsonResponse(statusCode, {'message': 'nope'});
        });

        // Each sub-case gets its own storage so persisted state from one
        // queue can't leak into the next via a shared storage key.

        // 408: transient, must be kept.
        SharedPreferences.setMockInitialValues({});
        final timeoutQueue = await OfflineRequestQueue(
          storage: await VeloraStorageService().init(),
          api: api,
        ).load();
        await timeoutQueue.enqueue(
          OfflineRequest(
            id: '1',
            method: 'POST',
            path: '/notes/timeout',
            data: {'title': 'first'},
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await timeoutQueue.flush();
        expect(timeoutQueue.pending, hasLength(1));

        // 429: transient, must be kept.
        SharedPreferences.setMockInitialValues({});
        final rateLimitedQueue = await OfflineRequestQueue(
          storage: await VeloraStorageService().init(),
          api: api,
        ).load();
        await rateLimitedQueue.enqueue(
          OfflineRequest(
            id: '2',
            method: 'POST',
            path: '/notes/rate-limited',
            data: {'title': 'second'},
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await rateLimitedQueue.flush();
        expect(rateLimitedQueue.pending, hasLength(1));

        // 400: permanent, must be discarded.
        SharedPreferences.setMockInitialValues({});
        final badQueue = await OfflineRequestQueue(
          storage: await VeloraStorageService().init(),
          api: api,
        ).load();
        await badQueue.enqueue(
          OfflineRequest(
            id: '3',
            method: 'POST',
            path: '/notes/bad',
            data: {'title': 'third'},
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await badQueue.flush();
        expect(badQueue.pending, isEmpty);

        expect(receivedPaths, [
          '/notes/timeout',
          '/notes/rate-limited',
          '/notes/bad',
        ]);
      },
    );

    test('flush halts and keeps the queue intact on a 5xx server error', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await VeloraStorageService().init();
      final receivedPaths = <String>[];
      final api = await _apiService((options) {
        receivedPaths.add(options.path);
        return ResponseBody.fromString('Server exploded', 500);
      });

      final queue = await OfflineRequestQueue(storage: storage, api: api).load();
      await queue.enqueue(
        OfflineRequest(
          id: '1',
          method: 'POST',
          path: '/notes',
          data: {'title': 'first'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await queue.enqueue(
        OfflineRequest(
          id: '2',
          method: 'POST',
          path: '/notes/2',
          data: {'title': 'second'},
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await queue.flush();

      expect(receivedPaths, ['/notes']);
      expect(queue.pending, hasLength(2));
    });

    test('replays and persists a non-Map (List) payload correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await VeloraStorageService().init();
      final receivedData = <Object?>[];
      final api = await _apiService((options) {
        receivedData.add(options.data);
        return _jsonResponse(200, {'success': true});
      });

      final queue = await OfflineRequestQueue(storage: storage, api: api).load();
      await queue.enqueue(
        OfflineRequest(
          id: '1',
          method: 'POST',
          path: '/notes/bulk',
          data: ['first', 'second'],
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      // Round-trip through persist/reload before replaying.
      final reloaded = await OfflineRequestQueue(storage: storage, api: api).load();
      expect(reloaded.pending, hasLength(1));
      expect(reloaded.pending.single.data, ['first', 'second']);

      await reloaded.flush();

      expect(receivedData.single, ['first', 'second']);
      expect(reloaded.pending, isEmpty);
    });
  });

  group('OfflineQueueInterceptor', () {
    test(
      'excludes auth endpoints from queuing',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = await VeloraStorageService().init();
        final api = await _apiService((_) => _jsonResponse(200, {'success': true}));
        final queue = await OfflineRequestQueue(storage: storage, api: api).load();
        final interceptor = OfflineQueueInterceptor(
          queue,
          excludedPaths: {'/auth/login', '/auth/logout'},
        );

        for (final path in ['/auth/login', '/auth/logout']) {
          final err = DioException(
            type: DioExceptionType.connectionError,
            requestOptions: RequestOptions(
              path: path,
              method: 'POST',
              data: {'email': 'a', 'password': 'b'},
            ),
          );
          interceptor.onError(err, _NoopErrorHandler());
        }

        // The enqueue call (if any) is fire-and-forget; give it a chance to
        // run before asserting it never happened.
        await pumpEventQueue();
        expect(queue.pending, isEmpty);
      },
    );

    test(
      'does not queue a request with a non-serializable body',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = await VeloraStorageService().init();
        final api = await _apiService((_) => _jsonResponse(200, {'success': true}));
        final queue = await OfflineRequestQueue(storage: storage, api: api).load();
        final interceptor = OfflineQueueInterceptor(queue);

        final err = DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(
            path: '/uploads',
            method: 'POST',
            data: FormData(),
          ),
        );
        interceptor.onError(err, _NoopErrorHandler());

        await pumpEventQueue();
        expect(queue.pending, isEmpty);
      },
    );

    test(
      'a replay that fails again during flush is not re-enqueued',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = await VeloraStorageService().init();
        final api = await _apiService((options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        });

        final queue = await OfflineRequestQueue(storage: storage, api: api).load();
        final interceptor = OfflineQueueInterceptor(queue);
        // Attach the interceptor to the same Dio instance the queue replays
        // through, so a failed replay runs through onError just like a
        // real request would.
        api.addInterceptor(interceptor);

        await queue.enqueue(
          OfflineRequest(
            id: '1',
            method: 'POST',
            path: '/notes',
            data: {'title': 'first'},
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        expect(queue.pending, hasLength(1));

        await queue.flush();

        // The replay failed with a connection error (still offline), so
        // flush halts and keeps the original item — but the interceptor
        // must not have queued a second copy of it while isFlushing was true.
        expect(queue.pending, hasLength(1));
        expect(queue.pending.single.id, '1');
      },
    );
  });

  group('VeloraOfflinePlugin', () {
    test(
      'registers services, adds the interceptor, and flushes on reconnect',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = await VeloraStorageService().init();
        final receivedPaths = <String>[];
        final api = await _apiService((options) {
          receivedPaths.add(options.path);
          return _jsonResponse(200, {'success': true});
        });
        final lifecycle = VeloraLifecycleRegistry();

        Get.put<VeloraStorageService>(storage);
        Get.put<VeloraApiService>(api);
        Get.put<VeloraLifecycleRegistry>(lifecycle);

        const config = VeloraConfig(
          appName: 'Test',
          apiBaseUrl: 'https://example.test',
        );
        final context = VeloraContext(config);
        final source = ToggleConnectivitySource(online: false);
        final plugin = VeloraOfflinePlugin(source: source);

        await plugin.register(context);

        expect(VeloraOffline.connectivity, isA<ConnectivityService>());
        expect(VeloraOffline.queue, isA<OfflineRequestQueue>());
        expect(VeloraOffline.isOnline, isFalse);
        expect(api.dio.interceptors, contains(isA<OfflineQueueInterceptor>()));

        await VeloraOffline.queue.enqueue(
          OfflineRequest(
            id: '1',
            method: 'POST',
            path: '/notes',
            data: {'title': 'queued'},
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        source.setOnline(true);
        // Allow the fire-and-forget flush triggered by onOnline to complete.
        await pumpEventQueue();

        expect(receivedPaths, ['/notes']);
        expect(VeloraOffline.queue.pending, isEmpty);
        expect(VeloraOffline.isOnline, isTrue);

        // Enqueue a fresh item so beforeLogout()'s clear() is actually
        // exercised, rather than operating on an already-empty queue.
        await VeloraOffline.queue.enqueue(
          OfflineRequest(
            id: '2',
            method: 'POST',
            path: '/notes',
            data: {'title': 'queued before logout'},
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        expect(VeloraOffline.queue.pending, isNotEmpty);

        await lifecycle.beforeLogout();
        expect(VeloraOffline.queue.pending, isEmpty);
      },
    );

    test(
      'replays a persisted queue on startup when already online, '
      'without any connectivity event',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = await VeloraStorageService().init();
        final receivedPaths = <String>[];
        final api = await _apiService((options) {
          receivedPaths.add(options.path);
          return _jsonResponse(200, {'success': true});
        });

        // Simulate a previous session that queued a write and was closed
        // before it could flush: persist an item directly via the queue,
        // then let the plugin's own queue (created in register()) load it
        // back from the same underlying storage.
        final seedQueue = await OfflineRequestQueue(storage: storage, api: api).load();
        await seedQueue.enqueue(
          OfflineRequest(
            id: '1',
            method: 'POST',
            path: '/notes',
            data: {'title': 'queued before restart'},
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        final lifecycle = VeloraLifecycleRegistry();
        Get.put<VeloraStorageService>(storage);
        Get.put<VeloraApiService>(api);
        Get.put<VeloraLifecycleRegistry>(lifecycle);

        const config = VeloraConfig(
          appName: 'Test',
          apiBaseUrl: 'https://example.test',
        );
        final context = VeloraContext(config);
        // Already online at startup -- no connectivity transition ever fires.
        final source = ToggleConnectivitySource(online: true);
        final plugin = VeloraOfflinePlugin(source: source);

        await plugin.register(context);
        // register() kicks off the startup flush fire-and-forget; let it run.
        await pumpEventQueue();

        expect(receivedPaths, ['/notes']);
        expect(VeloraOffline.queue.pending, isEmpty);
      },
    );
  });
}

/// An [ErrorInterceptorHandler] that swallows `next()` instead of completing
/// its internal completer. Calling `onError` directly (outside a real Dio
/// request pipeline) with the real handler leaves that completer's future
/// un-awaited, which surfaces as an unhandled async error in the test zone;
/// this fake sidesteps that since these tests only care about queue side
/// effects, not the propagated error.
class _NoopErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException error) {}
}

Future<VeloraApiService> _apiService(
  FutureOr<ResponseBody> Function(RequestOptions options) handler,
) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await VeloraStorageService().init();
  final api = VeloraApiService(
    config: const VeloraConfig(
      appName: 'Test',
      apiBaseUrl: 'https://example.test',
    ),
    storage: storage,
  );
  api.dio.httpClientAdapter = _FakeAdapter(handler);
  return api;
}

ResponseBody _jsonResponse(int statusCode, Object? body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

class _FakeAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
