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

/// The location of the top-level `dependencies:` block within a
/// `pubspec.yaml` [content] string, as found by [pubspecDependenciesBlock]:
/// [start] is the index (into [content]) of the first character of the
/// block body — right after the `dependencies:` line — and [body] is that
/// block's own text (every line belonging to it, up to but not including the
/// next top-level key, or the end of the file).
class PubspecDependenciesBlock {
  final int start;
  final String body;
  const PubspecDependenciesBlock(this.start, this.body);
}

/// Locates the top-level `dependencies:` block in a `pubspec.yaml` [content]
/// string. Tolerates a trailing inline `#` comment on the `dependencies:`
/// line itself (e.g. `dependencies: # runtime deps`) — valid YAML that a
/// bare `^dependencies:\s*$` match would otherwise miss. Returns `null` if no
/// such block exists.
///
/// Single source of truth for what counts as "the `dependencies:` block",
/// shared by [addDependencyToPubspec] (which inserts into it) and
/// [pubspecDeclaresDependency] (which only reads it), so `velora install`
/// and `velora doctor` can never drift apart on the definition. Pure.
PubspecDependenciesBlock? pubspecDependenciesBlock(String content) {
  final depBlockPattern = RegExp(
    r'^dependencies:[ \t]*(#.*)?$',
    multiLine: true,
  );
  final match = depBlockPattern.firstMatch(content);
  if (match == null) return null;

  final blockStart = match.end;
  final topLevelKeyPattern = RegExp(r'^[^\s#].*$', multiLine: true);
  final nextTopLevelKeys = topLevelKeyPattern.allMatches(content, blockStart);
  final blockEnd = nextTopLevelKeys.isEmpty
      ? content.length
      : nextTopLevelKeys.first.start;
  return PubspecDependenciesBlock(
    blockStart,
    content.substring(blockStart, blockEnd),
  );
}

/// Returns whether [name] is declared *under the top-level `dependencies:`
/// block* of a `pubspec.yaml` [content] string (a `dev_dependencies:` or
/// `dependency_overrides:` entry with the same name does not count). Used by
/// `velora doctor` to decide whether a package is installed. Pure.
bool pubspecDeclaresDependency(String content, String name) {
  final block = pubspecDependenciesBlock(content);
  if (block == null) return false;

  final depPattern = RegExp(
    '^\\s+${RegExp.escape(name)}\\s*:',
    multiLine: true,
  );
  return depPattern.hasMatch(block.body);
}

/// Inserts `name: constraint` as the first entry under a top-level
/// `dependencies:` block in a `pubspec.yaml` [content] string. If [name] is
/// already declared as a dependency *within the `dependencies:` block*
/// (any constraint), returns [content] unchanged — an entry with the same
/// name under `dev_dependencies:` or `dependency_overrides:` does not count
/// and will still get a fresh entry added under `dependencies:`. If there is
/// no `dependencies:` block, one is appended. Pure and idempotent.
String addDependencyToPubspec(String content, String name, String constraint) {
  final block = pubspecDependenciesBlock(content);
  if (block == null) {
    final separator = content.endsWith('\n') ? '' : '\n';
    return '$content$separator\ndependencies:\n  $name: $constraint\n';
  }

  // YAML permits any consistent (non-zero) indentation for block-mapping
  // children, not just 2 spaces, so match on arbitrary leading whitespace
  // rather than hardcoding `  `.
  final existingDepPattern = RegExp(
    '^\\s+${RegExp.escape(name)}\\s*:',
    multiLine: true,
  );
  if (existingDepPattern.hasMatch(block.body)) return content;

  return content.replaceRange(
    block.start,
    block.start,
    '\n  $name: $constraint',
  );
}

/// The bounds of a `Velora.boot(...)` call's argument list, as located
/// inside a masked (comment/string-blanked) copy of some source text:
/// [argsStart] is the index of the first character after the opening `(`,
/// and [argsEnd] is the index of the matching closing `)`. Both offsets are
/// valid into the *unmasked* source too, since [_maskNonCode] preserves
/// length and position.
class _BootCallBounds {
  final int argsStart;
  final int argsEnd;
  const _BootCallBounds(this.argsStart, this.argsEnd);
}

/// Locates the first executable `Velora.boot(` call in [mask] — a string
/// already run through [_maskNonCode], so a mention inside a comment or
/// string literal can never match here. Tolerates optional whitespace
/// between `boot` and the opening paren (e.g. `Velora.boot (`). Returns
/// `null` if no such call exists in [mask].
///
/// Shared by [wirePluginIntoBoot], [mainCallsVeloraBoot], and
/// [bootWiresPlugin] so all three agree on what counts as "the real boot
/// call".
_BootCallBounds? _findVeloraBootCall(String mask) {
  final bootPattern = RegExp(r'Velora\.boot\s*\(');
  final bootMatch = bootPattern.firstMatch(mask);
  if (bootMatch == null) return null;

  // Walk forward from the opening paren to find its matching close, so
  // callers only look for arguments that belong to this call (and not to
  // some unrelated list elsewhere in the file). Walk the mask so parens
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
  return _BootCallBounds(bootMatch.end, callEnd - 1);
}

/// Returns whether [mainContent] contains a real, executable
/// `Velora.boot(...)` call — as opposed to `Velora.boot(` merely being
/// mentioned inside a `//`/`/* */` comment or a string literal (see
/// [_maskNonCode]). Tolerates optional whitespace before the opening paren
/// (`Velora.boot (`). Pure.
bool mainCallsVeloraBoot(String mainContent) {
  return _findVeloraBootCall(_maskNonCode(mainContent)) != null;
}

/// Returns whether [pluginExpr] appears inside the `plugins: [...]` list
/// argument of the real, executable `Velora.boot(...)` call in
/// [mainContent] — not merely somewhere else in the file (a comment, a
/// string literal, an unrelated list, or even a `plugins:` argument that
/// isn't a plain inline list literal). Reuses the same masking and
/// call-locating logic as [wirePluginIntoBoot] so `velora doctor` and
/// `velora install` agree on what "wired into `Velora.boot()`" means. Pure.
bool bootWiresPlugin(String mainContent, String pluginExpr) {
  final mask = _maskNonCode(mainContent);
  final call = _findVeloraBootCall(mask);
  if (call == null) return false;

  final maskedCallBody = mask.substring(call.argsStart, call.argsEnd);
  final pluginsListPattern = RegExp(r'plugins\s*:\s*\[([^\]]*)\]');
  final pluginsMatch = pluginsListPattern.firstMatch(maskedCallBody);
  if (pluginsMatch == null) return false;

  final callBody = mainContent.substring(call.argsStart, call.argsEnd);
  final wholeMatchText = maskedCallBody.substring(
    pluginsMatch.start,
    pluginsMatch.end,
  );
  final listStart = pluginsMatch.start + wholeMatchText.indexOf('[') + 1;
  final listEnd = pluginsMatch.end - 1;
  final listContent = callBody.substring(listStart, listEnd);
  return listContent.contains(pluginExpr);
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

  final call = _findVeloraBootCall(mask);
  if (call == null) {
    return PluginWireResult(content, false);
  }

  final maskedCallBody = mask.substring(call.argsStart, call.argsEnd);
  final callBody = content.substring(call.argsStart, call.argsEnd);

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
    content = content.replaceRange(call.argsStart, call.argsEnd, newCallBody);
    return PluginWireResult(content, true);
  }

  final trimmedBody = callBody.trim();
  final separator = trimmedBody.isEmpty
      ? ''
      : (trimmedBody.endsWith(',') ? ' ' : ', ');
  final insertAt = call.argsEnd;
  content = content.replaceRange(
    insertAt,
    insertAt,
    '${separator}plugins: [$pluginExpr]',
  );
  return PluginWireResult(content, true);
}
