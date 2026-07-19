const veloraCliName = 'velora_cli';
const veloraCliVersion = '0.0.1';

/// Describes a Velora plugin package that `velora install <package>` knows
/// how to add to a generated app: its pub dependency, its `Velora.boot`
/// wiring, and human-readable post-install notes.
class VeloraPackageInstall {
  final String name;
  final String constraint;
  final String importLine;
  final String pluginExpr;
  final List<String> notes;

  const VeloraPackageInstall({
    required this.name,
    required this.constraint,
    required this.importLine,
    required this.pluginExpr,
    required this.notes,
  });
}

/// Catalog of packages installable via `velora install <package>`.
const veloraPackageCatalog = <String, VeloraPackageInstall>{
  'velora_offline': VeloraPackageInstall(
    name: 'velora_offline',
    constraint: '^0.0.1',
    importLine: "import 'package:velora_offline/velora_offline.dart';",
    pluginExpr: 'VeloraOfflinePlugin()',
    notes: [
      'Added velora_offline and wired VeloraOfflinePlugin() into Velora.boot().',
      'Use it anywhere: `if (VeloraOffline.isOnline) { ... }`.',
      'Note: until velora_offline is published to pub.dev, use a git or path dependency override.',
    ],
  ),
};

/// Inserts `name: constraint` as the first entry under a top-level
/// `dependencies:` block in a `pubspec.yaml` [content] string. If [name] is
/// already declared as a dependency *within the `dependencies:` block*
/// (any constraint), returns [content] unchanged — an entry with the same
/// name under `dev_dependencies:` or `dependency_overrides:` does not count
/// and will still get a fresh entry added under `dependencies:`. If there is
/// no `dependencies:` block, one is appended. Pure and idempotent.
String addDependencyToPubspec(String content, String name, String constraint) {
  final depBlockPattern = RegExp(r'^dependencies:\s*$', multiLine: true);
  final match = depBlockPattern.firstMatch(content);
  if (match == null) {
    final separator = content.endsWith('\n') ? '' : '\n';
    return '$content$separator\ndependencies:\n  $name: $constraint\n';
  }

  final blockStart = match.end;
  final topLevelKeyPattern = RegExp(r'^[^\s#].*$', multiLine: true);
  final nextTopLevelKeys = topLevelKeyPattern.allMatches(content, blockStart);
  final blockEnd = nextTopLevelKeys.isEmpty
      ? content.length
      : nextTopLevelKeys.first.start;
  final blockBody = content.substring(blockStart, blockEnd);

  // YAML permits any consistent (non-zero) indentation for block-mapping
  // children, not just 2 spaces, so match on arbitrary leading whitespace
  // rather than hardcoding `  `.
  final existingDepPattern = RegExp(
    '^\\s+${RegExp.escape(name)}\\s*:',
    multiLine: true,
  );
  if (existingDepPattern.hasMatch(blockBody)) return content;

  return content.replaceRange(
    blockStart,
    blockStart,
    '\n  $name: $constraint',
  );
}

/// Result of attempting to wire a plugin into `Velora.boot(...)`.
class PluginWireResult {
  final String content;
  final bool wired;

  const PluginWireResult(this.content, this.wired);
}

/// Builds an offset-preserving mask of [source]: every character inside a
/// `//` line comment, a `/* ... */` block comment, or a single- or
/// double-quoted string literal is replaced with a space, while every other
/// character — and the overall length, so all offsets into [source] still
/// line up — is left untouched. This lets callers locate code constructs
/// (like a `Velora.boot(` call) by scanning the mask, without being fooled
/// by a mention of the same text inside a doc comment or a string literal.
///
/// This is a pragmatic scanner, not a full Dart lexer: it does not
/// special-case triple-quoted strings or raw (`r'...'`) strings, but it does
/// handle ordinary `'...'`/`"..."` strings with backslash-escaped
/// characters, which covers the vast majority of real `main.dart` files.
String _maskNonCode(String source) {
  final buffer = StringBuffer();
  final len = source.length;
  var i = 0;
  while (i < len) {
    final char = source[i];
    final next = i + 1 < len ? source[i + 1] : '';

    if (char == '/' && next == '/') {
      buffer.write('  ');
      i += 2;
      while (i < len && source[i] != '\n') {
        buffer.write(' ');
        i++;
      }
      continue;
    }

    if (char == '/' && next == '*') {
      buffer.write('  ');
      i += 2;
      while (i < len && !(source[i] == '*' && i + 1 < len && source[i + 1] == '/')) {
        buffer.write(source[i] == '\n' ? '\n' : ' ');
        i++;
      }
      if (i < len) {
        buffer.write('  ');
        i += 2;
      }
      continue;
    }

    if (char == "'" || char == '"') {
      final quote = char;
      buffer.write(' ');
      i++;
      while (i < len && source[i] != quote) {
        if (source[i] == r'\' && i + 1 < len) {
          buffer.write(source[i] == '\n' ? '\n' : ' ');
          i++;
          buffer.write(source[i] == '\n' ? '\n' : ' ');
          i++;
        } else {
          buffer.write(source[i] == '\n' ? '\n' : ' ');
          i++;
        }
      }
      if (i < len) {
        buffer.write(' ');
        i++;
      }
      continue;
    }

    buffer.write(char);
    i++;
  }
  return buffer.toString();
}

/// Adds [importLine] (if absent) and inserts [pluginExpr] into the
/// `plugins: [...]` list passed to the real `Velora.boot(...)` call inside
/// [mainContent] — a `Velora.boot(` mentioned only in a comment or string
/// literal is ignored (see [_maskNonCode]). Idempotent: if [pluginExpr]
/// already appears anywhere in the content, the content is returned
/// unchanged with `wired: true`. If no real `Velora.boot(` call is found,
/// the import may still be added, but `wired` is false.
///
/// If the call already has a `plugins:` argument that is a plain inline
/// list literal (e.g. `plugins: [Foo()]`), [pluginExpr] is merged into it.
/// If it has a `plugins:` argument that is anything else — a `const [...]`
/// list, an identifier, a function call, etc. — merging isn't attempted:
/// splicing into a `const` list would require either dropping `const` or
/// proving [pluginExpr] is itself a const expression, and splicing into an
/// arbitrary expression isn't generally safe either. In that case nothing is
/// inserted and `wired: false` is returned so the caller can fall back to
/// printing manual-wiring guidance, which is the safe, honest choice.
PluginWireResult wirePluginIntoBoot(
  String mainContent, {
  required String importLine,
  required String pluginExpr,
}) {
  if (mainContent.contains(pluginExpr)) {
    return PluginWireResult(mainContent, true);
  }

  var content = mainContent;
  final importUriMatch = RegExp(
    r'package:[a-zA-Z0-9_]+/[a-zA-Z0-9_.]+\.dart',
  ).firstMatch(importLine);
  final importUri = importUriMatch?.group(0);
  final importAlreadyPresent =
      content.contains(importLine) ||
      (importUri != null &&
          RegExp(
            "import\\s+['\"]${RegExp.escape(importUri)}['\"]",
          ).hasMatch(content));
  if (!importAlreadyPresent) {
    final importPattern = RegExp(
      r"""^import\s+['"][^'"]*['"];.*$""",
      multiLine: true,
    );
    final imports = importPattern.allMatches(content).toList();
    if (imports.isEmpty) {
      content = '$importLine\n$content';
    } else {
      final lastImportEnd = imports.last.end;
      content = content.replaceRange(
        lastImportEnd,
        lastImportEnd,
        '\n$importLine',
      );
    }
  }

  // Build an offset-preserving mask of `content` *after* the import edit
  // above (so its offsets match `content`'s), with comments and string
  // literals blanked out. A `Velora.boot(` that only appears in a doc
  // comment or a string literal can never survive into this mask, since the
  // masked text is all spaces there.
  final mask = _maskNonCode(content);

  final bootPattern = RegExp(r'Velora\.boot\(');
  final bootMatch = bootPattern.firstMatch(mask);
  if (bootMatch == null) {
    return PluginWireResult(content, false);
  }

  // Walk forward from the opening paren to find its matching close, so we
  // only look for a `plugins:` argument that belongs to this call (and not
  // to some unrelated list elsewhere in the file). Walk the mask so parens
  // inside strings/comments can't miscount the depth.
  var depth = 1;
  var i = bootMatch.end;
  while (i < mask.length && depth > 0) {
    final char = mask[i];
    if (char == '(') depth++;
    if (char == ')') depth--;
    i++;
  }
  final callEnd = i; // index just past the matching ')'
  final maskedCallBody = mask.substring(bootMatch.end, callEnd - 1);
  final callBody = content.substring(bootMatch.end, callEnd - 1);

  // Does a `plugins:` named argument exist at all (searched in code only)?
  final pluginsArgPattern = RegExp(r'(?:^|[({,\s])plugins\s*:');
  final hasPluginsArg = pluginsArgPattern.hasMatch(maskedCallBody);

  final pluginsListPattern = RegExp(r'plugins\s*:\s*\[([^\]]*)\]');
  final pluginsMatch = pluginsListPattern.firstMatch(maskedCallBody);

  if (hasPluginsArg && pluginsMatch == null) {
    // A `plugins:` argument exists but isn't a plain inline `[...]` literal
    // (e.g. `const [...]`, an identifier, a function call). Don't touch it —
    // inserting a second `plugins:` would be uncompilable, and merging into
    // it isn't safe in general. Let the caller fall back to manual guidance.
    return PluginWireResult(content, false);
  }

  if (pluginsMatch != null) {
    // Re-slice the REAL content (not the mask) for the list body text. The
    // `Match` API only exposes offsets for the whole match, not per-group,
    // so derive group 1's span from the position of the literal `[` (which,
    // being unmasked code, sits at the same index in both `mask` and
    // `content`) through one before the final `]` that the pattern matched.
    final wholeMatchText = maskedCallBody.substring(
      pluginsMatch.start,
      pluginsMatch.end,
    );
    final listStart = pluginsMatch.start + wholeMatchText.indexOf('[') + 1;
    final listEnd = pluginsMatch.end - 1;
    final listContent = callBody.substring(listStart, listEnd);
    final trimmed = listContent.trim();
    final newListContent = trimmed.isEmpty
        ? pluginExpr
        : '$pluginExpr, $trimmed';
    final newCallBody = callBody.replaceRange(
      pluginsMatch.start,
      pluginsMatch.end,
      'plugins: [$newListContent]',
    );
    content = content.replaceRange(bootMatch.end, callEnd - 1, newCallBody);
    return PluginWireResult(content, true);
  }

  final trimmedBody = callBody.trim();
  final separator = trimmedBody.isEmpty
      ? ''
      : (trimmedBody.endsWith(',') ? ' ' : ', ');
  final insertAt = callEnd - 1;
  content = content.replaceRange(
    insertAt,
    insertAt,
    '${separator}plugins: [$pluginExpr]',
  );
  return PluginWireResult(content, true);
}
