/// What SQLite should do when an `INSERT` violates a uniqueness constraint
/// (e.g. re-inserting an existing primary key).
///
/// Mirrors SQLite's own `ON CONFLICT` clause (and the identically-named,
/// identically-valued enum the old sqflite-backed engine exposed from
/// `package:sqflite_common`), so call sites didn't need to change across the
/// drift engine swap -- only the import moved to `package:velora_db`.
enum ConflictAlgorithm {
  /// Aborts the current statement and rolls back the entire transaction.
  rollback,

  /// Aborts the current statement, keeping earlier changes in the current
  /// transaction. SQLite's default when no conflict clause is given.
  abort,

  /// Aborts the current statement, but changes prior to the failing row
  /// within the same statement are kept, and the transaction continues.
  fail,

  /// Skips the row that would violate the constraint and continues.
  ignore,

  /// Deletes the pre-existing conflicting row before inserting the new one.
  replace;

  /// The `OR <ALGORITHM>` SQL fragment for this conflict algorithm.
  String get sqlClause => switch (this) {
    ConflictAlgorithm.rollback => 'OR ROLLBACK',
    ConflictAlgorithm.abort => 'OR ABORT',
    ConflictAlgorithm.fail => 'OR FAIL',
    ConflictAlgorithm.ignore => 'OR IGNORE',
    ConflictAlgorithm.replace => 'OR REPLACE',
  };
}
