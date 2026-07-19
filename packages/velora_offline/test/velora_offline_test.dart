import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/velora.dart';
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
      final source = FakeConnectivitySource(initial: true);
      final service = await ConnectivityService(source).init();

      expect(service.isOnline.value, isTrue);

      source.push(false);
      await Future<void>.delayed(Duration.zero);
      expect(service.isOnline.value, isFalse);

      source.push(true);
      await Future<void>.delayed(Duration.zero);
      expect(service.isOnline.value, isTrue);

      service.dispose();
    });

    test('fires onOnline callbacks only on offline -> online transition', () async {
      final source = FakeConnectivitySource(initial: false);
      final service = await ConnectivityService(source).init();

      var calls = 0;
      service.onOnline(() async {
        calls += 1;
      });

      // Already offline -> offline is not a transition.
      source.push(false);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 0);

      source.push(true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);

      // online -> online is not a transition.
      source.push(true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);

      service.dispose();
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
        final source = FakeConnectivitySource(initial: false);
        final plugin = VeloraOfflinePlugin(source: source);

        await plugin.register(context);

        expect(VeloraOffline.connectivity, isA<ConnectivityService>());
        expect(VeloraOffline.queue, isA<OfflineRequestQueue>());
        expect(VeloraOffline.isOnline, isFalse);
        expect(api.dio.interceptors.length, greaterThan(1));

        await VeloraOffline.queue.enqueue(
          OfflineRequest(
            id: '1',
            method: 'POST',
            path: '/notes',
            data: {'title': 'queued'},
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        source.push(true);
        // Allow the fire-and-forget flush triggered by onOnline to complete.
        await pumpEventQueue();

        expect(receivedPaths, ['/notes']);
        expect(VeloraOffline.queue.pending, isEmpty);
        expect(VeloraOffline.isOnline, isTrue);

        await lifecycle.beforeLogout();
        expect(VeloraOffline.queue.pending, isEmpty);
      },
    );
  });
}

class FakeConnectivitySource implements ConnectivitySource {
  bool _connected;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  FakeConnectivitySource({bool initial = true}) : _connected = initial;

  void push(bool online) {
    _connected = online;
    _controller.add(online);
  }

  @override
  Future<bool> isConnected() async => _connected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;
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
