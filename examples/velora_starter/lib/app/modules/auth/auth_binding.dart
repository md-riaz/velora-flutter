import 'package:get/get.dart';

import 'auth_remote_data_source.dart';
import 'auth_repository.dart';
import 'starter_auth_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StarterAuthRemoteDataSource>()) {
      Get.put<StarterAuthRemoteDataSource>(
        MockStarterAuthRemoteDataSource(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<StarterAuthRepository>()) {
      Get.put<StarterAuthRepository>(
        StarterAuthRepositoryImpl(Get.find<StarterAuthRemoteDataSource>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<StarterAuthService>()) {
      Get.put<StarterAuthService>(
        StarterAuthService(Get.find<StarterAuthRepository>()),
        permanent: true,
      );
    }
  }
}
