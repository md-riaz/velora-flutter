import 'package:velora/velora.dart';

import 'velora_table.dart';

/// Adapts a [VeloraTable] to the [VeloraRepository] contract, so a local
/// sqflite-backed table is a drop-in repository alongside remote-backed
/// implementations.
class VeloraDbRepository<T, ID> implements VeloraRepository<T, ID> {
  final VeloraTable<T, ID> table;

  VeloraDbRepository(this.table);

  @override
  Future<List<T>> index() => table.all();

  @override
  Future<T> show(ID id) async {
    final model = await table.find(id);
    if (model == null) {
      throw StateError('No row found in "${table.table}" for id $id.');
    }
    return model;
  }

  @override
  Future<T> store(Map<String, dynamic> data) => table.create(data);

  @override
  Future<T> update(ID id, Map<String, dynamic> data) async {
    await table.update(id, data);
    return show(id);
  }

  @override
  Future<void> destroy(ID id) async {
    await table.delete(id);
  }
}
