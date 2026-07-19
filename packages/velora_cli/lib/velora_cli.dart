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
/// already declared as a dependency (any constraint), returns [content]
/// unchanged. If there is no `dependencies:` block, one is appended. Pure
/// and idempotent.
String addDependencyToPubspec(String content, String name, String constraint) {
  final existingDepPattern = RegExp(
    '^  $name\\s*:',
    multiLine: true,
  );
  if (existingDepPattern.hasMatch(content)) return content;

  final depBlockPattern = RegExp(r'^dependencies:\s*$', multiLine: true);
  final match = depBlockPattern.firstMatch(content);
  if (match == null) {
    final separator = content.endsWith('\n') ? '' : '\n';
    return '$content$separator\ndependencies:\n  $name: $constraint\n';
  }

  final insertAt = match.end;
  return content.replaceRange(
    insertAt,
    insertAt,
    '\n  $name: $constraint',
  );
}

/// Result of attempting to wire a plugin into `Velora.boot(...)`.
class PluginWireResult {
  final String content;
  final bool wired;

  const PluginWireResult(this.content, this.wired);
}

/// Adds [importLine] (if absent) and inserts [pluginExpr] into the
/// `plugins: [...]` list passed to `Velora.boot(...)` inside [mainContent].
/// Idempotent: if [pluginExpr] already appears anywhere in the content, the
/// content is returned unchanged with `wired: true`. If no `Velora.boot(`
/// call is found, the import may still be added, but `wired` is false.
PluginWireResult wirePluginIntoBoot(
  String mainContent, {
  required String importLine,
  required String pluginExpr,
}) {
  if (mainContent.contains(pluginExpr)) {
    return PluginWireResult(mainContent, true);
  }

  var content = mainContent;
  if (!content.contains(importLine)) {
    final importPattern = RegExp(r"^import\s+'[^']*';.*$", multiLine: true);
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

  final bootPattern = RegExp(r'Velora\.boot\(');
  final bootMatch = bootPattern.firstMatch(content);
  if (bootMatch == null) {
    return PluginWireResult(content, false);
  }

  // Walk forward from the opening paren to find its matching close, so we
  // only look for a `plugins:` argument that belongs to this call (and not
  // to some unrelated list elsewhere in the file).
  var depth = 1;
  var i = bootMatch.end;
  while (i < content.length && depth > 0) {
    final char = content[i];
    if (char == '(') depth++;
    if (char == ')') depth--;
    i++;
  }
  final callEnd = i; // index just past the matching ')'
  final callBody = content.substring(bootMatch.end, callEnd - 1);

  final pluginsListPattern = RegExp(r'plugins\s*:\s*\[([^\]]*)\]');
  final pluginsMatch = pluginsListPattern.firstMatch(callBody);
  if (pluginsMatch != null) {
    final listContent = pluginsMatch.group(1)!;
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

  final insertAt = bootMatch.end;
  content = content.replaceRange(
    insertAt,
    insertAt,
    '\n    plugins: [$pluginExpr],\n   ',
  );
  return PluginWireResult(content, true);
}
