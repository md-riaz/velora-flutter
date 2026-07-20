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
  /// Defaults to [ConflictAlgorithm.replace], so re-inserting an existing
  /// primary key (e.g. a client-generated id) replaces the row instead of
  /// throwing a unique-constraint error — convenient for upsert-shaped
  /// writes. Be aware that SQLite implements `REPLACE` as a `DELETE` of the
  /// conflicting row followed by an `INSERT`: this can cascade `ON DELETE`
  /// foreign key actions, and any column not present in [data] reverts to
  /// its table default rather than keeping its previous value. Pass a
  /// different [conflictAlgorithm] (e.g. [ConflictAlgorithm.abort], the
  /// SQLite default) when that data loss / cascade risk isn't acceptable
  /// for a given write.
  ///
  /// Id resolution: if [data] already has a value for [primaryKey] (the
  /// caller-supplied id case, typically a `String` UUID), that value is
  /// returned as-is. Otherwise `db.insert` hands back the raw SQLite rowid
  /// (always an `int`). If [ID] is `int`, that rowid *is* the id and is
  /// returned directly. If [ID] is some other type (e.g. a `String`
  /// primary key populated by a SQL-side default rather than by the
  /// caller), the raw rowid is not a valid [ID] on its own, so the row is
  /// read back by `rowid` to recover the real primary key value; if that
  /// still isn't an [ID], a [StateError] is thrown rather than silently
  /// returning the wrong type.
  Future<ID> insert(
    Map<String, dynamic> data, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    final rowId = await db.insert(
      table,
      data,
      conflictAlgorithm: conflictAlgorithm,
    );
    final providedId = data[primaryKey];
    if (providedId != null) {
      return providedId as ID;
    }
    if (rowId is ID) {
      return rowId as ID;
    }
    final rows = await db.query(table, where: 'rowid = ?', whereArgs: [rowId]);
    if (rows.isEmpty) {
      throw StateError(
        'Insert into "$table" succeeded (rowid $rowId) but no row could be '
        'read back by that rowid to resolve its "$primaryKey" value.',
      );
    }
    final resolvedId = rows.first[primaryKey];
    if (resolvedId is ID) {
      return resolvedId;
    }
    throw StateError(
      'Insert into "$table" produced a "$primaryKey" value of type '
      '${resolvedId.runtimeType} (rowid $rowId), which is not a valid $ID. '
      'Either supply "$primaryKey" explicitly in the inserted data, or '
      'ensure the table\'s primary key type matches $ID.',
    );
  }

  /// Inserts [data] and returns the newly created model, read back from the
  /// database so DB-computed defaults (e.g. an autoincrement id) are
  /// reflected. See [insert] for [conflictAlgorithm] semantics and id
  /// resolution.
  Future<T> create(
    Map<String, dynamic> data, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    final id = await insert(data, conflictAlgorithm: conflictAlgorithm);
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
