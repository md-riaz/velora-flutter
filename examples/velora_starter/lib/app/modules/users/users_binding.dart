import 'package:get/get.dart';

import 'users_controller.dart';
import 'users_remote_data_source.dart';
import 'users_repository.dart';
import 'users_service.dart';

class UsersBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UsersRemoteDataSource>()) {
      Get.put<UsersRemoteDataSource>(MockUsersRemoteDataSource());
    }
    if (!Get.isRegistered<UsersRepository>()) {
      Get.put<UsersRepository>(
        UsersRepositoryImpl(Get.find<UsersRemoteDataSource>()),
      );
    }
    if (!Get.isRegistered<UsersService>()) {
      Get.put<UsersService>(UsersService(Get.find<UsersRepository>()));
    }
    Get.put<UsersController>(UsersController(Get.find<UsersService>()));
  }

  static Future<void> disposeScope() async {
    if (Get.isRegistered<UsersController>()) {
      await Get.delete<UsersController>(force: true);
    }
    if (Get.isRegistered<UsersService>()) {
      await Get.delete<UsersService>(force: true);
    }
    if (Get.isRegistered<UsersRepository>()) {
      await Get.delete<UsersRepository>(force: true);
    }
    if (Get.isRegistered<UsersRemoteDataSource>()) {
      await Get.delete<UsersRemoteDataSource>(force: true);
    }
  }
}
