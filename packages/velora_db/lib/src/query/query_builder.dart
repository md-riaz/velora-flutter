import 'dart:async';

import 'package:drift/drift.dart';

import '../velora_sql_database.dart';

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
/// fragments (values are always parameterized separately via bound
/// [Variable]s).
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

/// An immutable, fluent, Eloquent-style query builder over a single [table],
/// compiled to raw SQL run through drift's `customSelect`.
///
/// Every method returns a new [QueryBuilder] rather than mutating in place,
/// so a builder can be safely reused/branched. Terminal methods ([get],
/// [first], [count], [watch]) compile the accumulated conditions to a
/// parameterized `WHERE` clause -- column and operator tokens are
/// allowlisted, and every value is bound as a drift [Variable], so a value
/// containing e.g. `'` or `;` is always treated as data, never as SQL.
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
  ///
  /// In SQL, `= NULL` / `!= NULL` never match anything -- comparing to NULL
  /// with an equality operator always evaluates to NULL (neither true nor
  /// false), not "is null". So when [value] is `null` and [op] is `=`, this
  /// is rewritten to `IS` (compiling to `column IS NULL`); when [op] is `!=`
  /// or `<>`, it's rewritten to `IS NOT` (compiling to `column IS NOT
  /// NULL`). `IS` / `IS NOT` passed explicitly with a non-null [value] are
  /// left as ordinary bound parameters.
  QueryBuilder whereOp(String column, String op, Object? value) {
    _validateColumn(column);
    var normalizedOp = op.trim().toUpperCase();
    if (!_allowedOperators.contains(normalizedOp)) {
      throw ArgumentError.value(op, 'op', 'Unsupported operator');
    }
    if (value == null) {
      if (normalizedOp == '=') {
        normalizedOp = 'IS';
      } else if (normalizedOp == '!=' || normalizedOp == '<>') {
        normalizedOp = 'IS NOT';
      }
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
  Future<List<Map<String, dynamic>>> get(VeloraSqlDatabase db) async {
    final rows = await db
        .customSelect(_selectSql(), variables: _variables)
        .get();
    return rows.map((row) => row.data).toList();
  }

  /// Runs the compiled query with an implicit `LIMIT 1` and returns the
  /// first matching row, or `null` if there isn't one.
  Future<Map<String, dynamic>?> first(VeloraSqlDatabase db) async {
    final rows = await limit(1).get(db);
    return rows.isEmpty ? null : rows.first;
  }

  /// The number of rows matching the accumulated where conditions (ignores
  /// [orderBy] / [limit] / [offset]).
  Future<int> count(VeloraSqlDatabase db) async {
    final sql = StringBuffer('SELECT COUNT(*) AS count FROM $table');
    final where = _whereClause;
    if (where != null) sql.write(' WHERE $where');
    final rows = await db
        .customSelect(sql.toString(), variables: _variables)
        .get();
    final value = rows.first.data['count'];
    if (value is int) return value;
    return int.parse(value.toString());
  }

  /// A reactive version of [get]: emits the current matching rows
  /// immediately, then re-emits every time [table] changes (any insert/
  /// update/delete that calls `db.notifyUpdates` for it -- which every write
  /// path in this package does).
  ///
  /// The returned stream is broadcast (each `listen()` gets its own
  /// independent subscription and initial emission, via `Stream.multi`) and
  /// cancels its underlying `tableUpdates` subscription cleanly when the
  /// listener cancels.
  Stream<List<Map<String, dynamic>>> watch(VeloraSqlDatabase db) {
    return Stream.multi((controller) {
      var closed = false;

      Future<void> emit() async {
        if (closed) return;
        try {
          final rows = await get(db);
          if (!closed) controller.add(rows);
        } catch (error, stackTrace) {
          if (!closed) controller.addError(error, stackTrace);
        }
      }

      unawaited(emit());
      final subscription = db
          .tableUpdates(TableUpdateQuery.onTableName(table))
          .listen((_) => emit());

      controller.onCancel = () async {
        closed = true;
        await subscription.cancel();
      };
    }, isBroadcast: true);
  }

  String _selectSql() {
    final sql = StringBuffer('SELECT * FROM $table');
    final where = _whereClause;
    if (where != null) sql.write(' WHERE $where');
    if (_orderBy != null) sql.write(' ORDER BY $_orderBy');
    if (_limit != null) sql.write(' LIMIT $_limit');
    if (_offset != null) sql.write(' OFFSET $_offset');
    return sql.toString();
  }

  /// Whether [w] should compile to a bare `column IS [NOT] NULL` with no
  /// bound `?` placeholder, rather than a parameterized comparison.
  static bool _isUnboundNullCheck(_WhereClause w) =>
      w.value == null && (w.op == 'IS' || w.op == 'IS NOT');

  String? get _whereClause => _wheres.isEmpty
      ? null
      : _wheres
            .map(
              (w) => _isUnboundNullCheck(w)
                  ? '${w.column} ${w.op} NULL'
                  : '${w.column} ${w.op} ?',
            )
            .join(' AND ');

  // Must stay in lockstep with _whereClause: both iterate _wheres in the
  // same order and skip the same unbound-null-check clauses, so the `?`
  // placeholders line up positionally with the variables bound into them.
  List<Variable> get _variables => _wheres.isEmpty
      ? const []
      : _wheres
            .where((w) => !_isUnboundNullCheck(w))
            .map((w) => Variable<Object>(w.value))
            .toList();
}
