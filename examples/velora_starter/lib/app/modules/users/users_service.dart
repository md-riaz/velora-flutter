import 'package:get/get.dart';
import 'package:velora/velora.dart';

import 'user_model.dart';
import 'users_repository.dart';

class UsersService extends GetxService {
  final UsersRepository repository;

  UsersService(this.repository);

  final users = <UserModel>[].obs;

  Future<ApiResponse<List<UserModel>>> index() async {
    final result = await repository.index();
    users.assignAll(result);
    return ApiResponse(success: true, data: result);
  }

  Future<ApiResponse<PaginatedData<UserModel>>> paginate({
    int page = 1,
    int perPage = 15,
  }) async {
    final result = await repository.paginate(page: page, perPage: perPage);
    users.assignAll(result.data);
    return ApiResponse(success: true, data: result);
  }

  Future<ApiResponse<UserModel>> show(int id) async {
    final result = await repository.show(id);
    return ApiResponse(success: true, data: result);
  }

  Future<ApiResponse<UserModel>> store(Map<String, dynamic> data) async {
    final result = await repository.store(data);
    await index();
    return ApiResponse(success: true, data: result, message: 'User created');
  }

  Future<ApiResponse<UserModel>> update(
    int id,
    Map<String, dynamic> data,
  ) async {
    final result = await repository.update(id, data);
    await index();
    return ApiResponse(success: true, data: result, message: 'User updated');
  }

  Future<ApiResponse<void>> destroy(int id) async {
    await repository.destroy(id);
    await index();
    return const ApiResponse(success: true, message: 'User deleted');
  }
}
