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
/// - Values are trimmed. A value starting with a quote (`"` or `'`) is
///   scanned for its matching *closing* quote first; everything after that
///   closing quote (e.g. a trailing ` # comment`) is ignored, and the quotes
///   themselves are stripped:
///   - Inside **double** quotes, `\n`, `\t`, `\"`, and `\\` escapes are
///     interpreted, and a `\"` is not treated as the closing quote.
///   - Inside **single** quotes, the content is taken literally (no escape
///     processing) up to the first `'`.
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
  if (rawValue.startsWith('"')) {
    final closingIndex = _findClosingDoubleQuote(rawValue);
    if (closingIndex != -1) {
      return _unescapeDouble(rawValue.substring(1, closingIndex));
    }
  }

  if (rawValue.startsWith("'")) {
    final closingIndex = _findClosingSingleQuote(rawValue);
    if (closingIndex != -1) {
      return rawValue.substring(1, closingIndex);
    }
  }

  return _stripInlineComment(rawValue).trim();
}

/// Finds the index of the closing (unescaped) `"` that matches the opening
/// quote at index 0, or `-1` if there isn't one. `\"` and `\\` are honored
/// as escapes while scanning, matching [_unescapeDouble]'s interpretation.
int _findClosingDoubleQuote(String value) {
  for (var i = 1; i < value.length; i++) {
    final char = value[i];
    if (char == r'\' && i + 1 < value.length) {
      i++; // Skip the escaped character -- it can't be a closing quote.
      continue;
    }
    if (char == '"') return i;
  }
  return -1;
}

/// Finds the index of the closing `'` that matches the opening quote at
/// index 0, or `-1` if there isn't one. Single-quoted values are literal,
/// so the first `'` after the opening one closes it -- no escapes.
int _findClosingSingleQuote(String value) {
  final index = value.indexOf("'", 1);
  return index;
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
