import 'package:get/get.dart';
import 'package:velora/velora.dart';

import '../auth/logout_state.dart';
import 'user_model.dart';
import 'users_service.dart';

class UsersController extends VeloraController {
  final UsersService service;

  UsersController(this.service);

  final users = <UserModel>[].obs;
  final currentPage = 1.obs;
  final perPage = 15.obs;
  final hasMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch({int page = 1}) async {
    if (isVeloraLogoutRunning() || isClosed) return;
    await run(() async {
      // Uses the paginated service method so replacing the mock with Laravel API
      // pagination later only requires data-source changes.
      final response = await service.paginate(
        page: page,
        perPage: perPage.value,
      );
      if (isVeloraLogoutRunning() || isClosed) return;
      final result = response.data;
      users.assignAll(result?.data ?? const []);
      currentPage.value = result?.currentPage ?? page;
      hasMore.value = result?.hasMore ?? false;
    });
  }

  Future<void> create(String name, String email) async {
    if (isVeloraLogoutRunning() || isClosed) return;
    await run(() async {
      await service.store({'name': name, 'email': email});
      await fetch();
    }, successMessage: 'User created');
  }

  Future<void> saveUser(int id, String name, String email) async {
    if (isVeloraLogoutRunning() || isClosed) return;
    await run(() async {
      await service.update(id, {'name': name, 'email': email});
      await fetch();
    }, successMessage: 'User updated');
  }

  Future<void> destroy(int id) async {
    if (isVeloraLogoutRunning() || isClosed) return;
    final confirmed = await Velora.dialog.confirm(
      title: 'Delete user?',
      message: 'This action cannot be undone.',
    );
    if (!confirmed) return;
    await run(() async {
      await service.destroy(id);
      await fetch();
    }, successMessage: 'User deleted');
  }
}
