import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/velora.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    // Back the secure enclave with an in-memory mock so token round-trips work
    // under flutter_test without the (opt-in, off-by-default) plaintext fallback.
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  test('validator handles required and email rules', () {
    expect(Velora.validator.required(''), isNotNull);
    expect(Velora.validator.required('ok'), isNull);
    expect(Velora.validator.email('bad'), isNotNull);
    expect(Velora.validator.email('admin@example.com'), isNull);
  });

  test('api response maps Laravel validation errors', () {
    final response = ApiResponse<Object?>.fromJson({
      'success': false,
      'message': 'The email field is required.',
      'errors': {
        'email': ['The email field is required.'],
      },
    });

    expect(response.success, isFalse);
    expect(response.errors['email'], ['The email field is required.']);
  });

  test(
    'api service normalizes Laravel validation errors without network',
    () async {
      final api = await _apiService((options) {
        expect(options.path, '/users');
        expect(options.headers['Authorization'], 'Bearer test-token');
        return _jsonResponse(422, {
          'message': 'The given data was invalid.',
          'errors': {
            'email': ['The email field is required.'],
            'password': 'Password is too short.',
          },
        });
      }, token: 'test-token');

      expect(
        api.post<Object?>('/users', data: {'email': ''}),
        throwsA(
          isA<ApiException>()
              .having(
                (error) => error.message,
                'message',
                'The given data was invalid.',
              )
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.errors['email'], 'email errors', [
                'The email field is required.',
              ])
              .having((error) => error.errors['password'], 'password errors', [
                'Password is too short.',
              ]),
        ),
      );
    },
  );

  test('api service preserves status on non-json error responses', () async {
    final api = await _apiService(
      (_) => ResponseBody.fromString('Server exploded', 500),
    );

    expect(
      api.get<Object?>('/boom'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 500)
            .having((error) => error.errors, 'errors', isEmpty)
            .having((error) => error.message, 'message', isNotEmpty),
      ),
    );
  });

  test('auth user parses roles permissions features and defaults safely', () {
    final user = AuthUser.fromJson({
      'id': 1.5,
      'name': 42,
      'email': 'admin@example.com',
      'roles': ['admin', 7],
      'permissions': ['users.view'],
      'features': ['users'],
    });

    expect(user.id, 1);
    expect(user.name, '42');
    expect(user.email, 'admin@example.com');
    expect(user.roles, ['admin', '7']);
    expect(user.permissions, ['users.view']);
    expect(user.features, ['users']);

    final fallback = AuthUser.fromJson({'roles': 'admin'});
    expect(fallback.id, 0);
    expect(fallback.name, isEmpty);
    expect(fallback.email, isNull);
    expect(fallback.roles, isEmpty);
  });

  test(
    'permission service reflects current auth user roles and permissions',
    () async {
      final auth = await _authService();
      final service = PermissionService(auth: auth);

      expect(service.can('users.view'), isFalse);
      expect(service.cannot('users.view'), isTrue);
      expect(service.hasRole('admin'), isFalse);

      auth.currentUser.value = const AuthUser(
        id: 1,
        name: 'Admin',
        email: 'admin@example.com',
        roles: ['admin', 'editor'],
        permissions: ['users.view', 'users.create'],
      );

      expect(service.can('users.view'), isTrue);
      expect(service.cannot('users.delete'), isTrue);
      expect(service.hasRole('admin'), isTrue);
      expect(service.hasAnyRole(['viewer', 'editor']), isTrue);
      expect(service.hasAnyRole(['viewer', 'guest']), isFalse);
      expect(service.hasAllPermissions(['users.view', 'users.create']), isTrue);
      expect(
        service.hasAllPermissions(['users.view', 'users.delete']),
        isFalse,
      );
    },
  );

  test(
    'feature service registers, toggles, syncs, filters permissions, and flushes scope',
    () async {
      final auth = await _authService();
      auth.currentUser.value = const AuthUser(
        id: 1,
        name: 'Admin',
        email: 'admin@example.com',
        permissions: ['reports.view'],
      );
      Get.put<PermissionService>(PermissionService(auth: auth));

      final service = FeatureService(
        permissionCheck: Get.find<PermissionService>().can,
      );
      service.registerAll([
        const VeloraFeature(
          id: 'reports',
          name: 'Reports',
          permission: 'reports.view',
          menuItems: [
            VeloraMenuItem(label: 'Reports', route: '/reports'),
            VeloraMenuItem(
              label: 'Reports Admin',
              route: '/reports/admin',
              permission: 'reports.admin',
            ),
          ],
        ),
        const VeloraFeature(
          id: 'billing',
          name: 'Billing',
          permission: 'billing.view',
          menuItems: [VeloraMenuItem(label: 'Billing', route: '/billing')],
        ),
      ]);

      expect(service.canAccess('reports'), isFalse);

      service.enable('reports');
      service.enable('billing');

      expect(service.enabled('reports'), isTrue);
      expect(service.canAccess('reports'), isTrue);
      expect(service.canAccess('billing'), isFalse);
      expect(service.menuItems.map((item) => item.label), ['Reports']);

      service.disable('reports');
      expect(service.enabled('reports'), isFalse);
      expect(service.canAccess('reports'), isFalse);

      service.syncFromUserFeatures(['reports']);
      expect(service.enabled('reports'), isTrue);
      expect(service.enabled('billing'), isFalse);

      await service.flushUserScope();
      expect(service.enabled('reports'), isFalse);

      var userScopeDisposed = 0;
      service.registerUserScopeDisposer(() async {
        userScopeDisposed += 1;
      });

      var featureDisposed = 0;
      service.register(
        VeloraFeature(
          id: 'exports',
          name: 'Exports',
          disposers: [
            () async {
              featureDisposed += 1;
            },
          ],
        ),
      );

      service.enable('exports');
      await service.flushUserScope();
      expect(service.enabled('exports'), isFalse);
      expect(userScopeDisposed, 1);
      expect(featureDisposed, 1);
    },
  );

  test(
    'feature service accepts an injected permission resolver without a registered PermissionService',
    () {
      final service = FeatureService(
        permissionCheck: (permission) => permission == 'reports.view',
      );
      service.register(
        const VeloraFeature(
          id: 'reports',
          name: 'Reports',
          permission: 'reports.view',
        ),
      );
      service.register(
        const VeloraFeature(
          id: 'billing',
          name: 'Billing',
          permission: 'billing.view',
        ),
      );
      service.enable('reports');
      service.enable('billing');

      expect(service.canAccess('reports'), isTrue);
      expect(service.canAccess('billing'), isFalse);
    },
  );

  test('theme service tracks mode changes', () {
    final service = ThemeService();

    expect(service.current, ThemeMode.system);

    service.useDark();
    expect(service.current, ThemeMode.dark);

    service.useLight();
    expect(service.current, ThemeMode.light);

    service.useSystem();
    expect(service.current, ThemeMode.system);
  });

  test(
    'storage json helpers round-trip maps and ignore invalid json',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await VeloraStorageService().init();

      await storage.setJson('profile', {
        'name': 'Admin',
        'roles': ['admin'],
      });

      expect(storage.getJson('profile'), {
        'name': 'Admin',
        'roles': ['admin'],
      });

      await storage.setJson('list', ['not', 'a', 'map']);
      expect(storage.getJson('list'), isNull);

      await storage.set('broken', '{nope');
      expect(storage.getJson('broken'), isNull);
    },
  );

  test('paginated data parses Laravel pagination meta', () {
    final page = PaginatedData<int>.fromJson({
      'data': [1, 2],
      'meta': {'current_page': 1, 'last_page': 2, 'per_page': 2, 'total': 4},
    }, (value) => value! as int);

    expect(page.hasMore, isTrue);
    expect(page.total, 4);
  });

  test(
    'notification service exposes core state and local adapter methods',
    () async {
      final repository = InMemoryNotificationRepository([
        AppNotification(
          id: 'one',
          type: 'users.created',
          title: 'User created',
          body: 'A user was created',
          createdAt: DateTime.parse('2026-06-24T10:30:00Z'),
        ),
      ]);
      final pushAdapter = NoopPushAdapter(
        permissionGranted: true,
        token: 'push-token',
      );
      final localAdapter = InMemoryLocalNotificationAdapter();
      final auth = await _authService();
      final permission = PermissionService(auth: auth);
      final feature = FeatureService(permissionCheck: permission.can);
      const notificationConfig = VeloraNotificationConfig(
        provider: PushProvider.none,
      );
      final service = NotificationService(
        repository: repository,
        pushAdapter: pushAdapter,
        localAdapter: localAdapter,
        auth: auth,
        feature: feature,
        permission: permission,
        nav: VeloraNav(),
        config: notificationConfig,
      );

      await service.initForUser();

      expect(service.initialized.value, isTrue);
      expect(service.permissionGranted.value, isTrue);
      expect(service.pushToken.value, 'push-token');
      expect(service.notifications, hasLength(1));
      expect(service.unreadCount.value, 1);
      expect(repository.registeredTokens.single['provider'], 'none');

      await service.showLocal(title: 'Saved', body: 'Done');
      await service.scheduleLocal(
        id: 'reminder_1',
        title: 'Reminder',
        body: 'Submit',
        dateTime: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(localAdapter.shown, hasLength(1));
      expect(localAdapter.scheduled, contains('reminder_1'));

      await service.markAsRead('one');
      expect(service.unreadCount.value, 0);
      expect(service.notifications.single.isRead, isTrue);

      await service.cancelLocal('reminder_1');
      expect(localAdapter.scheduled, isEmpty);

      await service.disposeForUser();
      expect(service.initialized.value, isFalse);
      expect(repository.unregisteredTokens, ['push-token']);
    },
  );

  test(
    'auth lifecycle initializes and disposes notifications when configured',
    () async {
      var requestIndex = 0;
      final api = await _apiService((options) {
        requestIndex += 1;
        if (requestIndex == 1) {
          return _jsonResponse(200, {
            'success': true,
            'data': {
              'token': 'auth-token',
              'user': {
                'id': 7,
                'name': 'Admin',
                'email': 'admin@example.test',
                'permissions': ['notifications.view'],
                'features': ['notifications'],
              },
            },
          });
        }
        return _jsonResponse(200, {'success': true, 'data': []});
      });
      final storage = await _storage();
      final repository = InMemoryNotificationRepository();
      // Declared before `auth` so the login hook below can close over it —
      // it is only invoked once login() runs, by which point `notify` has
      // already been assigned below, making this deterministic.
      late final NotificationService notify;
      final auth = await AuthService(
        api: api,
        storage: storage,
        config: const VeloraAuthConfig(),
        onLoginSuccess: (user) async {
          await notify.initForUser();
        },
      ).init();
      final permission = PermissionService(auth: auth);
      final feature = FeatureService(permissionCheck: permission.can);
      const notificationConfig = VeloraNotificationConfig(
        provider: PushProvider.none,
        requestPermissionAfterLogin: true,
      );
      final nav = VeloraNav();
      notify = NotificationService(
        repository: repository,
        pushAdapter: NoopPushAdapter(
          permissionGranted: true,
          token: 'push-token',
        ),
        localAdapter: InMemoryLocalNotificationAdapter(),
        auth: auth,
        feature: feature,
        permission: permission,
        nav: nav,
        config: notificationConfig,
      );
      final lifecycle = VeloraLifecycleRegistry();
      final coordinator = LogoutCoordinator(
        lifecycle: lifecycle,
        auth: auth,
        nav: nav,
        logoutRedirectRoute: '/login',
      );
      auth.attachLogoutCoordinator(coordinator);

      Get.put<AuthService>(auth);
      Get.put<NotificationService>(notify);
      Get.put<VeloraApiService>(api);
      Get.put<VeloraLifecycleRegistry>(lifecycle);
      Get.put<LogoutCoordinator>(coordinator);

      // Mirrors boot(): dispose notifications for the logged-out user via
      // the Phase-1 logout-hook lifecycle, not AuthService itself.
      lifecycle.register(
        VeloraLogoutHook(
          onBeforeLogout: () async {
            if (!Get.isRegistered<NotificationService>()) return;
            await Get.find<NotificationService>().disposeForUser();
          },
        ),
      );

      Velora.config = const VeloraConfig(
        appName: 'Test',
        apiBaseUrl: 'https://example.test',
        notifications: notificationConfig,
      );

      await Velora.login({
        'email': 'admin@example.test',
        'password': 'secret',
      });

      expect(auth.check, isTrue);
      expect(notify.initialized.value, isTrue);
      expect(repository.registeredTokens.single['token'], 'push-token');

      await Velora.logout();

      expect(auth.check, isFalse);
      expect(notify.initialized.value, isFalse);
      expect(repository.unregisteredTokens, ['push-token']);
    },
  );

  test(
    'logout coordinator is idempotent and clears local session after remote failure',
    () async {
      var logoutRequests = 0;
      final api = await _apiService((options) {
        logoutRequests += 1;
        return _jsonResponse(500, {'message': 'Server unavailable'});
      });
      final storage = await _storage();
      await storage.setToken('auth-token');
      await storage.setJson('velora.auth.user', {
        'id': 7,
        'name': 'Admin',
        'email': 'admin@example.test',
      });
      final lifecycle = VeloraLifecycleRegistry();
      final auth = await AuthService(
        api: api,
        storage: storage,
        config: const VeloraAuthConfig(),
      ).init();
      final coordinator = LogoutCoordinator(
        lifecycle: lifecycle,
        auth: auth,
        nav: VeloraNav(),
        logoutRedirectRoute: '/login',
      );
      auth.attachLogoutCoordinator(coordinator);

      Get.put<AuthService>(auth);
      Get.put<VeloraApiService>(api);
      Get.put<LogoutCoordinator>(coordinator);
      Get.put<VeloraLifecycleRegistry>(lifecycle);
      Velora.config = const VeloraConfig(
        appName: 'Test',
        apiBaseUrl: 'https://example.test',
        auth: VeloraAuthConfig(logoutRedirectRoute: '/login'),
        notifications: VeloraNotificationConfig(enabled: false),
      );

      expect(auth.check, isTrue);

      await Future.wait([auth.logout(), Velora.logout()]);

      expect(logoutRequests, 1);
      expect(auth.check, isFalse);
      expect(auth.isLoggingOut, isFalse);
      expect(auth.state.value, SessionState.guest);
      expect(await storage.getToken(), isNull);
      expect(storage.getJson('velora.auth.user'), isNull);
    },
  );
  test('auth guard fails closed when Velora is not booted', () {
    // No AuthService registered → fail closed by default (redirect).
    expect(const VeloraAuthGuard().redirect('/dashboard'), '/login');
  });

  test('auth guard allows unbooted navigation only when opted in', () {
    expect(
      const VeloraAuthGuard(allowWhenUnbooted: true).redirect('/dashboard'),
      isNull,
    );
  });

  test('auth guard fails closed for unauthenticated users', () async {
    final auth = await _authService();
    Get.put<AuthService>(auth);
    Get.put<VeloraConfig>(
      const VeloraConfig(
        appName: 'Test',
        apiBaseUrl: 'https://example.test',
        auth: VeloraAuthConfig(logoutRedirectRoute: '/login'),
      ),
    );

    expect(const VeloraAuthGuard().redirect('/dashboard'), '/login');

    auth.isAuthenticated.value = true;
    expect(const VeloraAuthGuard().redirect('/dashboard'), isNull);
  });

  test('auth guard falls back to fallbackRoute when config is missing', () async {
    // Booted (AuthService present) but config unavailable → must still deny.
    Get.put<AuthService>(await _authService());
    expect(
      const VeloraAuthGuard(fallbackRoute: '/signin').redirect('/dashboard'),
      '/signin',
    );
  });

  test('storage never stores the token in plaintext by default', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await VeloraStorageService().init();
    await storage.setToken('secret-token');

    // Round-trips via the secure enclave...
    expect(await storage.getToken(), 'secret-token');
    // ...and leaves nothing in plaintext SharedPreferences.
    expect(storage.get<String>('velora.auth.token'), isNull);
    expect(storage.allowInsecureFallback, isFalse);
  });

  test('storage rethrows when secure storage fails and fallback is off', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await VeloraStorageService(
      secureStorage: _ThrowingSecureStorage(),
    ).init();

    await expectLater(storage.setToken('secret-token'), throwsA(anything));
    // Nothing was written to plaintext prefs.
    expect(storage.get<String>('velora.auth.token'), isNull);
  });

  test('storage insecure fallback persists token to prefs when opted in', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await VeloraStorageService(
      secureStorage: _ThrowingSecureStorage(),
      allowInsecureFallback: true,
    ).init();

    // Secure storage throws → the token round-trips through SharedPreferences.
    await storage.setToken('secret-token');
    expect(storage.get<String>('velora.auth.token'), 'secret-token');
    expect(await storage.getToken(), 'secret-token');
  });
}

/// Secure-storage double whose operations always throw, to exercise the
/// plaintext-fallback / fail-closed branches of [VeloraStorageService].
class _ThrowingSecureStorage extends FlutterSecureStorage {
  const _ThrowingSecureStorage();

  Never _boom() => throw Exception('secure storage unavailable');

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _boom();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _boom();

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _boom();
}

Future<AuthService> _authService() async {
  final api = await _apiService((_) => _jsonResponse(200, {'success': true}));
  final storage = await _storage();
  return AuthService(
    api: api,
    storage: storage,
    config: const VeloraAuthConfig(),
  ).init();
}

Future<VeloraApiService> _apiService(
  FutureOr<ResponseBody> Function(RequestOptions options) handler, {
  String? token,
}) async {
  final storage = await _storage();
  if (token != null) {
    await storage.setToken(token);
  }
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

Future<VeloraStorageService> _storage() async {
  SharedPreferences.setMockInitialValues({});
  return VeloraStorageService().init();
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
