abstract class VeloraRepository<T> {
  Future<List<T>> index();
  Future<T> show(int id);
  Future<T> store(Map<String, dynamic> data);
  Future<T> update(int id, Map<String, dynamic> data);
  Future<void> destroy(int id);
}

abstract class VeloraRemoteDataSource<T> {
  Future<List<T>> index();
  Future<T> show(int id);
  Future<T> store(Map<String, dynamic> data);
  Future<T> update(int id, Map<String, dynamic> data);
  Future<void> destroy(int id);
}
