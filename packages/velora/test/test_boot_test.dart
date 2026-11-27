import 'package:flutter_test/flutter_test.dart';
import 'package:velora/velora.dart';

class CustomUser implements Authenticatable {
  @override
  List<String> get roles => ['admin'];
  @override
  List<String> get permissions => ['read'];
  @override
  List<String> get features => ['feature'];
  @override
  Map<String, dynamic> toJson() => {};
}

class TestController extends VeloraController {}

class TestPlugin extends VeloraPlugin {
  @override
  String get name => 'test';
  @override
  Future<void> register(VeloraContext context) async =>
      context.put<String>('plugin');
}

void main() {
  tearDown(() async => Velora.reset());

  test('test boot provides isolated storage and default services', () async {
    await Velora.testBoot(plugins: [TestPlugin()]);
    expect(Get.testMode, isTrue);
    expect(Velora.config.notifications.enabled, isFalse);
    expect(Velora.storage, isA<InMemoryStorage>());
    expect(Get.find<String>(), 'plugin');
    await Velora.storage.setToken('token');
    await Velora.storage.setJson('key', {'value': 1});
    expect(await Velora.storage.getToken(), 'token');
    expect(Velora.storage.getJson('key'), {'value': 1});
    await Velora.testBoot();
    expect(await Velora.storage.getToken(), isNull);
    expect(Velora.storage.getJson('key'), isNull);
    expect(Velora.plugins, isEmpty);
    await Velora.reset();
    expect(Get.isRegistered<AuthService>(), isFalse);
  });

  test(
    'default and custom users are available with their proper types',
    () async {
      await Velora.testBoot();
      Velora.auth.currentUser.value = const AuthUser(id: 1, name: 'Ada');
      final AuthUser? user = Velora.auth.user;
      expect(user?.name, 'Ada');
      expect(Velora.auth.userAs<AuthUser>(), same(user));
      final custom = CustomUser();
      Velora.auth.currentUser.value = custom;
      expect(Velora.auth.user, isNull);
      expect(Velora.auth.userAs<CustomUser>(), same(custom));
      expect(Velora.permission.hasRole('admin'), isTrue);
      expect(Velora.permission.can('read'), isTrue);
    },
  );

  test('controller errorMessage reflects the reactive error', () {
    final controller = TestController();
    expect(controller.errorMessage, isNull);
    controller.error.value = 'Oops';
    expect(controller.errorMessage, 'Oops');
    controller.clearError();
    expect(controller.errorMessage, isNull);
  });
}
