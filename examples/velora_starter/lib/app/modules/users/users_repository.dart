import 'package:velora/velora.dart';

import 'user_model.dart';
import 'users_remote_data_source.dart';

abstract class UsersRepository implements VeloraRepository<UserModel> {
  Future<PaginatedData<UserModel>> paginate({int page = 1, int perPage = 15});
}

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource remote;

  const UsersRepositoryImpl(this.remote);

  @override
  Future<List<UserModel>> index() => remote.index();

  @override
  Future<PaginatedData<UserModel>> paginate({int page = 1, int perPage = 15}) {
    return remote.paginate(page: page, perPage: perPage);
  }

  @override
  Future<UserModel> show(int id) => remote.show(id);

  @override
  Future<UserModel> store(Map<String, dynamic> data) => remote.store(data);

  @override
  Future<UserModel> update(int id, Map<String, dynamic> data) =>
      remote.update(id, data);

  @override
  Future<void> destroy(int id) => remote.destroy(id);
}
