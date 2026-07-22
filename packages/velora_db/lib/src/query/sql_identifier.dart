/// A valid, unquoted SQL identifier: letters, digits, underscore, not
/// starting with a digit.
///
/// This is the single source of truth for the allowlist every raw-SQL
/// construction site in this package uses to validate a column/table name
/// before splicing it into a SQL fragment (values are always parameterized
/// separately via bound `Variable`s, never through this path).
final RegExp sqlIdentifierPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

/// Whether [identifier] is a valid, unquoted SQL identifier per
/// [sqlIdentifierPattern].
bool isValidSqlIdentifier(String identifier) =>
    sqlIdentifierPattern.hasMatch(identifier);

/// Throws an [ArgumentError] if [identifier] is not a valid, unquoted SQL
/// identifier per [sqlIdentifierPattern]. [argumentName] is used as the
/// argument name reported in the thrown error (e.g. `'column'`, `'table'`).
void validateSqlIdentifier(String identifier, {String argumentName = 'name'}) {
  if (!isValidSqlIdentifier(identifier)) {
    throw ArgumentError.value(identifier, argumentName, 'Invalid identifier');
  }
}
