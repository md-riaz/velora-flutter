/// Pure, dependency-free parser for `.env`-style files (the same dotenv
/// format popularized by Ruby's `dotenv` and used by Laravel).
///
/// Supported syntax:
/// - Blank lines and full-line `#` comments are ignored.
/// - An optional leading `export ` before the key (as in shell-sourceable
///   `.env` files) is stripped.
/// - Keys must match `[A-Za-z_][A-Za-z0-9_]*`; lines that don't look like
///   `KEY=VALUE` (or whose key doesn't match) are silently skipped rather
///   than throwing, so a malformed line doesn't take down the whole file.
/// - Values are trimmed. A value wrapped in matching single or double quotes
///   has the quotes stripped:
///   - Inside **double** quotes, `\n`, `\t`, `\"`, and `\\` escapes are
///     interpreted.
///   - Inside **single** quotes, the content is taken literally (no escape
///     processing).
///   - **Unquoted** values have a trailing ` #comment` stripped (a `#`
///     preceded by whitespace, to the end of the line).
/// - Duplicate keys: the last occurrence in the file wins.
final _keyLinePattern = RegExp(
  r'^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$',
);

Map<String, String> parseEnv(String content) {
  final result = <String, String>{};

  for (final rawLine in content.split('\n')) {
    // `.trim()` also strips a trailing `\r` left by CRLF-terminated files.
    final trimmed = rawLine.trim();

    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    final match = _keyLinePattern.firstMatch(trimmed);
    if (match == null) continue;

    final key = match.group(1)!;
    final rawValue = match.group(2)!.trim();
    result[key] = _parseValue(rawValue);
  }

  return result;
}

String _parseValue(String rawValue) {
  if (rawValue.length >= 2 &&
      rawValue.startsWith('"') &&
      rawValue.endsWith('"')) {
    return _unescapeDouble(rawValue.substring(1, rawValue.length - 1));
  }

  if (rawValue.length >= 2 &&
      rawValue.startsWith("'") &&
      rawValue.endsWith("'")) {
    return rawValue.substring(1, rawValue.length - 1);
  }

  return _stripInlineComment(rawValue).trim();
}

String _unescapeDouble(String value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    if (char == r'\' && i + 1 < value.length) {
      final next = value[i + 1];
      switch (next) {
        case 'n':
          buffer.write('\n');
          i++;
          continue;
        case 't':
          buffer.write('\t');
          i++;
          continue;
        case '"':
          buffer.write('"');
          i++;
          continue;
        case r'\':
          buffer.write(r'\');
          i++;
          continue;
      }
    }
    buffer.write(char);
  }
  return buffer.toString();
}

/// Strips a trailing ` #comment` (whitespace followed by `#` to end of
/// line) from an unquoted value.
String _stripInlineComment(String value) {
  final index = value.indexOf(RegExp(r'\s#'));
  if (index == -1) return value;
  return value.substring(0, index);
}
