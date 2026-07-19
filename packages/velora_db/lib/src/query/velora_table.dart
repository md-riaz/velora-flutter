import 'package:sqflite_common/sqlite_api.dart';

import 'query_builder.dart';

/// A single Eloquent-style table binding: maps rows in [table] to/from a
/// model type [T] keyed by [ID], via [fromMap] / [toMap].
///
/// [ID] follows the same convention as `VeloraRepository<T, ID>` — `int` for
/// autoincrement rowid tables, `String` for tables keyed by a caller-supplied
/// id (e.g. a UUID). [insert] adapts to both: if `data[primaryKey]` is
/// already present it's returned as-is (the `String` case), otherwise the
/// sqlite-assigned rowid is returned (the `int` autoincrement case).
class VeloraTable<T, ID> {
  final Database db;
  final String table;
  final T Function(Map<String, dynamic> row) fromMap;
  final Map<String, dynamic> Function(T model) toMap;
  final String primaryKey;

  VeloraTable({
    required this.db,
    required this.table,
    required this.fromMap,
    required this.toMap,
    this.primaryKey = 'id',
  });

  /// A fresh, unfiltered fluent [QueryBuilder] over [table].
  QueryBuilder query() => QueryBuilder(table);

  /// Every row in [table], mapped to [T].
  Future<List<T>> all() async {
    final rows = await query().get(db);
    return rows.map(fromMap).toList();
  }

  /// Looks up a single row by its primary key, or `null` if none exists.
  Future<T?> find(ID id) async {
    final row = await query().where(primaryKey, id).first(db);
    return row == null ? null : fromMap(row);
  }

  /// Convenience over [query]: every row where [column] equals [value],
  /// mapped to [T].
  Future<List<T>> where(String column, Object? value) async {
    final rows = await query().where(column, value).get(db);
    return rows.map(fromMap).toList();
  }

  /// Inserts a raw row and returns its id.
  ///
  /// Uses [ConflictAlgorithm.replace], so re-inserting an existing primary
  /// key (e.g. a client-generated id) replaces the row instead of throwing a
  /// unique-constraint error — a sensible default for upsert-shaped writes.
  Future<ID> insert(Map<String, dynamic> data) async {
    final rowId = await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final providedId = data[primaryKey];
    if (providedId != null) {
      return providedId as ID;
    }
    return rowId as ID;
  }

  /// Inserts [data] and returns the newly created model, read back from the
  /// database so DB-computed defaults (e.g. an autoincrement id) are
  /// reflected.
  Future<T> create(Map<String, dynamic> data) async {
    final id = await insert(data);
    final model = await find(id);
    if (model == null) {
      throw StateError(
        'Insert into "$table" did not produce a readable row for id $id.',
      );
    }
    return model;
  }

  /// Updates the row identified by [id] with [data]. Returns the number of
  /// rows affected (`0` or `1`).
  Future<int> update(ID id, Map<String, dynamic> data) {
    return db.update(table, data, where: '$primaryKey = ?', whereArgs: [id]);
  }

  /// Deletes the row identified by [id]. Returns the number of rows affected
  /// (`0` or `1`).
  Future<int> delete(ID id) {
    return db.delete(table, where: '$primaryKey = ?', whereArgs: [id]);
  }

  /// The number of rows in [table].
  Future<int> count() => query().count(db);
}
