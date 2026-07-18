/// Contract for a resource repository.
///
/// [T] is the model type and [ID] is the identifier type — use `String` for
/// UUID-keyed resources or `int` for auto-increment IDs.
///
/// > Note: this is a breaking change from the previous single-parameter
/// > `VeloraRepository<T>` (which hardcoded `int` ids). Dart has no default
/// > type arguments, so existing implementations must add the id type, e.g.
/// > `implements VeloraRepository<UserModel, int>`.
abstract class VeloraRepository<T, ID> {
  Future<List<T>> index();
  Future<T> show(ID id);
  Future<T> store(Map<String, dynamic> data);
  Future<T> update(ID id, Map<String, dynamic> data);
  Future<void> destroy(ID id);
}

/// Contract for the remote data source a [VeloraRepository] delegates to.
///
/// Mirrors [VeloraRepository] so a repository can forward straight through, or
/// adapt/cache around the remote source. [ID] follows the same convention.
abstract class VeloraRemoteDataSource<T, ID> {
  Future<List<T>> index();
  Future<T> show(ID id);
  Future<T> store(Map<String, dynamic> data);
  Future<T> update(ID id, Map<String, dynamic> data);
  Future<void> destroy(ID id);
}
