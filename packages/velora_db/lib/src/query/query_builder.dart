import 'package:sqflite_common/sqlite_api.dart';

/// Comparison operators [QueryBuilder.whereOp] accepts. Anything else is
/// rejected with [ArgumentError] rather than interpolated into SQL.
const _allowedOperators = {
  '=',
  '!=',
  '<>',
  '<',
  '<=',
  '>',
  '>=',
  'LIKE',
  'NOT LIKE',
  'IS',
  'IS NOT',
};

/// A valid, unquoted SQL identifier: letters, digits, underscore, not
/// starting with a digit. Used to allowlist column names passed into raw SQL
/// fragments (values are always parameterized separately via `whereArgs`).
final _validIdentifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

void _validateColumn(String column) {
  if (!_validIdentifier.hasMatch(column)) {
    throw ArgumentError.value(column, 'column', 'Invalid column name');
  }
}

class _WhereClause {
  final String column;
  final String op;
  final Object? value;

  const _WhereClause(this.column, this.op, this.value);
}

/// An immutable, fluent, Eloquent-style query builder over a single sqflite
/// [table].
///
/// Every method returns a new [QueryBuilder] rather than mutating in place,
/// so a builder can be safely reused/branched. Terminal methods ([get],
/// [first], [count]) compile the accumulated conditions to a parameterized
/// `where` / `whereArgs` pair for sqflite's `Database.query` — column and
/// operator tokens are allowlisted, and every value is bound as a
/// `whereArgs` parameter, so a value containing e.g. `'` or `;` is always
/// treated as data, never as SQL.
class QueryBuilder {
  final String table;
  final List<_WhereClause> _wheres;
  final String? _orderBy;
  final int? _limit;
  final int? _offset;

  QueryBuilder(this.table)
      : _wheres = const <_WhereClause>[],
        _orderBy = null,
        _limit = null,
        _offset = null;

  QueryBuilder._(
    this.table,
    this._wheres,
    this._orderBy,
    this._limit,
    this._offset,
  );

  /// Adds an equality condition: `column = value`.
  QueryBuilder where(String column, Object? value) =>
      whereOp(column, '=', value);

  /// Adds a condition using an explicit operator, e.g.
  /// `whereOp('age', '>', 18)`. [op] must be one of the allowlisted
  /// comparison operators (case-insensitive).
  QueryBuilder whereOp(String column, String op, Object? value) {
    _validateColumn(column);
    final normalizedOp = op.trim().toUpperCase();
    if (!_allowedOperators.contains(normalizedOp)) {
      throw ArgumentError.value(op, 'op', 'Unsupported operator');
    }
    return QueryBuilder._(
      table,
      [..._wheres, _WhereClause(column, normalizedOp, value)],
      _orderBy,
      _limit,
      _offset,
    );
  }

  /// Orders results by [column], ascending unless [desc] is `true`.
  QueryBuilder orderBy(String column, {bool desc = false}) {
    _validateColumn(column);
    return QueryBuilder._(
      table,
      _wheres,
      '$column ${desc ? 'DESC' : 'ASC'}',
      _limit,
      _offset,
    );
  }

  /// Limits the result set to [n] rows.
  QueryBuilder limit(int n) =>
      QueryBuilder._(table, _wheres, _orderBy, n, _offset);

  /// Skips the first [n] rows of the result set.
  QueryBuilder offset(int n) =>
      QueryBuilder._(table, _wheres, _orderBy, _limit, n);

  /// Runs the compiled query and returns the matching rows.
  Future<List<Map<String, dynamic>>> get(Database db) async {
    final rows = await db.query(
      table,
      where: _whereClause,
      whereArgs: _whereArgs,
      orderBy: _orderBy,
      limit: _limit,
      offset: _offset,
    );
    return rows.map(Map<String, dynamic>.from).toList();
  }

  /// Runs the compiled query with an implicit `LIMIT 1` and returns the
  /// first matching row, or `null` if there isn't one.
  Future<Map<String, dynamic>?> first(Database db) async {
    final rows = await limit(1).get(db);
    return rows.isEmpty ? null : rows.first;
  }

  /// The number of rows matching the accumulated where conditions (ignores
  /// [orderBy] / [limit] / [offset]).
  Future<int> count(Database db) async {
    final result = await db.query(
      table,
      columns: ['COUNT(*) AS count'],
      where: _whereClause,
      whereArgs: _whereArgs,
    );
    final value = result.first['count'];
    if (value is int) return value;
    return int.parse(value.toString());
  }

  String? get _whereClause => _wheres.isEmpty
      ? null
      : _wheres.map((w) => '${w.column} ${w.op} ?').join(' AND ');

  List<Object?>? get _whereArgs =>
      _wheres.isEmpty ? null : _wheres.map((w) => w.value).toList();
}
