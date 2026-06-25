import 'package:velora/velora.dart';

import 'auth_remote_data_source.dart';

abstract class StarterAuthRepository {
  Future<ApiResponse<Map<String, dynamic>>> login(
    Map<String, dynamic> credentials,
  );

  Future<ApiResponse<Map<String, dynamic>>> me(String token);

  Future<ApiResponse<void>> logout(String token);
}

class StarterAuthRepositoryImpl implements StarterAuthRepository {
  final StarterAuthRemoteDataSource remote;

  const StarterAuthRepositoryImpl(this.remote);

  @override
  Future<ApiResponse<Map<String, dynamic>>> login(
    Map<String, dynamic> credentials,
  ) {
    return remote.login(credentials);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> me(String token) =>
      remote.me(token);

  @override
  Future<ApiResponse<void>> logout(String token) => remote.logout(token);
}
