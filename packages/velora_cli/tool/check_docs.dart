// Verifies that documentation matches shipped code, and regenerates the
// doc blocks that are derived from registries.
//
//   tool/check_docs.sh            check only; exits 1 on any drift
//   tool/check_docs.sh --write    rewrite generated blocks, then check
//
// Sources of truth:
//   CLI commands          veloraCommands        (lib/velora_cli.dart)
//   Installable packages  veloraPackageCatalog  (lib/velora_cli.dart)
//   UI components         packages/velora_ui/components.json
//   SDK baseline          veloraMin*Version     (lib/velora_cli.dart)
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:velora_cli/velora_cli.dart';

late final String _root;
final _problems = <String>[];

void _fail(String message) => _problems.add(message);

String _read(String relative) => utf8.decode(
  File(p.join(_root, relative)).readAsBytesSync(),
  allowMalformed: true,
);

bool _exists(String relative) =>
    FileSystemEntity.typeSync(p.join(_root, relative)) !=
    FileSystemEntityType.notFound;

void main(List<String> args) {
  final write = args.contains('--write');
  final top = Process.runSync('git', ['rev-parse', '--show-toplevel']);
  if (top.exitCode != 0) {
    stderr.writeln('check_docs must run inside the git repository.');
    exit(2);
  }
  _root = top.stdout.toString().trim();

  final ui = _UiRegistry.load();
  final markdown = _trackedMarkdown();

  _checkGeneratedBlocks(ui, write: write);
  _checkUiRegistry(ui);
  _checkCommands(markdown);
  _checkPackages();
  _checkStaleClaims(ui);
  _checkLinksAndPaths(markdown);
  _checkBaselineAndHistory();

  if (_problems.isEmpty) {
    stdout.writeln(
      '✓ Docs match code '
      '(${markdown.length} Markdown files, ${veloraCommands.length} commands, '
      '${veloraPackageCatalog.length} packages, ${ui.names.length} UI exports).',
    );
    return;
  }
  for (final problem in _problems) {
    stderr.writeln('✗ $problem');
  }
  stderr.writeln('${_problems.length} documentation problem(s).');
  exit(1);
}

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

/// Tracked Markdown, minus vendored code, agent skills, and the two frozen
/// planning documents (historical by design; see [_checkBaselineAndHistory]).
List<String> _trackedMarkdown() {
  final result = Process.runSync('git', [
    'ls-files',
    '*.md',
  ], workingDirectory: _root);
  const skipPrefixes = ['third_party/', '.claude/', 'docs/planning/'];
  const skipFiles = {'velora.md', 'velora.part2.md'};
  return LineSplitter.split(result.stdout.toString())
      .where((f) => f.isNotEmpty)
      .where((f) => !skipPrefixes.any(f.startsWith))
      .where((f) => !skipFiles.contains(f))
      .toList();
}

class _UiLayer {
  _UiLayer(this.number, this.title, this.components);
  final int number;
  final String title;
  final List<({String name, String file})> components;
}

class _UiRegistry {
  _UiRegistry(this.layers);
  final List<_UiLayer> layers;

  static const path = 'packages/velora_ui/components.json';

  static _UiRegistry load() {
    final json = jsonDecode(_read(path)) as Map<String, dynamic>;
    return _UiRegistry([
      for (final layer in json['layers'] as List)
        _UiLayer(layer['layer'] as int, layer['title'] as String, [
          for (final c in layer['components'] as List)
            (name: c['name'] as String, file: c['file'] as String),
        ]),
    ]);
  }

  Iterable<String> get names =>
      layers.expand((l) => l.components.map((c) => c.name));
  Set<String> get files =>
      layers.expand((l) => l.components.map((c) => c.file)).toSet();
  int get maxLayer =>
      layers.map((l) => l.number).reduce((a, b) => a > b ? a : b);
}

// ---------------------------------------------------------------------------
// Generated blocks
// ---------------------------------------------------------------------------

String _commandsTable() {
  final rows = [
    '| Command | What it does |',
    '|---|---|',
    for (final c in veloraCommands)
      '| `${c.usage.replaceAll('|', r'\|')}` | ${c.summary} |',
  ];
  return rows.join('\n');
}

String _packagesTable({required String fromDir}) {
  final rows = [
    '| Package | What it is | Wiring | Docs |',
    '|---|---|---|---|',
    for (final pkg in veloraPackageCatalog.values)
      '| `${pkg.name}` | ${pkg.summary} | ${pkg.wiring} | '
          '[${p.basenameWithoutExtension(pkg.docs)}]'
          '(${p.posix.relative(pkg.docs, from: fromDir)}) |',
  ];
  return rows.join('\n');
}

String _uiLayersTable(_UiRegistry ui) {
  final rows = [
    '| Layer | Focus | Exports |',
    '|---|---|---|',
    for (final layer in ui.layers)
      '| ${layer.number} | ${layer.title} | '
          '${layer.components.map((c) => '`${c.name}`').join(', ')} |',
  ];
  return rows.join('\n');
}

void _checkGeneratedBlocks(_UiRegistry ui, {required bool write}) {
  final blocks = <(String file, String id, String source, String body)>[
    (
      'docs/commands.md',
      'cli-commands',
      'packages/velora_cli/lib/velora_cli.dart',
      _commandsTable(),
    ),
    (
      'docs/commands.md',
      'installable-packages',
      'packages/velora_cli/lib/velora_cli.dart',
      _packagesTable(fromDir: 'docs'),
    ),
    (
      'README.md',
      'installable-packages',
      'packages/velora_cli/lib/velora_cli.dart',
      _packagesTable(fromDir: '.'),
    ),
    ('docs/packages/ui.md', 'ui-layers', _UiRegistry.path, _uiLayersTable(ui)),
  ];

  for (final (file, id, source, body) in blocks) {
    final open =
        '<!-- generated:$id source=$source — do not edit; '
        'run tool/check_docs.sh --write -->';
    final close = '<!-- /generated:$id -->';
    final content = _read(file);
    final pattern = RegExp(
      '<!-- generated:${RegExp.escape(id)} [^\n]*-->\n.*?\n'
      '${RegExp.escape(close)}',
      dotAll: true,
    );
    final match = pattern.firstMatch(content);
    if (match == null) {
      _fail('$file: missing generated block "$id" ($open … $close).');
      continue;
    }
    final expected = '$open\n$body\n$close';
    if (match.group(0) == expected) continue;
    if (write) {
      File(p.join(_root, file)).writeAsStringSync(
        content.replaceRange(match.start, match.end, expected),
      );
      stdout.writeln('Regenerated $file ($id).');
    } else {
      _fail(
        '$file: generated block "$id" is stale — '
        'run tool/check_docs.sh --write and commit.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// velora_ui: exports ↔ registry ↔ docs
// ---------------------------------------------------------------------------

void _checkUiRegistry(_UiRegistry ui) {
  const lib = 'packages/velora_ui/lib';
  final exports = RegExp(
    r"^export '([^']+)';",
    multiLine: true,
  ).allMatches(_read('$lib/velora_ui.dart')).map((m) => m.group(1)!).toSet();

  for (final file in exports.difference(ui.files)) {
    _fail('${_UiRegistry.path}: exported file $file has no registry entry.');
  }
  for (final file in ui.files.difference(exports)) {
    _fail('${_UiRegistry.path}: $file is not exported by velora_ui.dart.');
  }

  // Every public top-level declaration in an exported file must be listed.
  final declaration = RegExp(
    r'^(?:(?:abstract|final|sealed|base|interface) )*'
    r'(?:class|enum|extension|mixin|typedef) (\w+)'
    r'|^[A-Z][\w<>?, ]* (\w+)\(',
    multiLine: true,
  );
  final registered = ui.names.toSet();
  final docs = _read('docs/packages/ui.md');
  for (final file in exports.intersection(ui.files)) {
    final declared = declaration
        .allMatches(_read('$lib/$file'))
        .map((m) => m.group(1) ?? m.group(2)!)
        .where((name) => !name.startsWith('_'))
        .toSet();
    for (final name in declared.difference(registered)) {
      _fail('${_UiRegistry.path}: public `$name` ($file) is not registered.');
    }
    for (final layer in ui.layers) {
      for (final c in layer.components.where((c) => c.file == file)) {
        if (!declared.contains(c.name)) {
          _fail('${_UiRegistry.path}: `${c.name}` is not declared in $file.');
        }
      }
    }
  }
  for (final name in registered) {
    if (!RegExp('\\b${RegExp.escape(name)}\\b').hasMatch(docs)) {
      _fail('docs/packages/ui.md: does not mention `$name`.');
    }
  }
}

// ---------------------------------------------------------------------------
// CLI: registry ↔ parser ↔ every mention in docs and generated templates
// ---------------------------------------------------------------------------

void _checkCommands(List<String> markdown) {
  const bin = 'packages/velora_cli/bin/velora_cli.dart';
  final source = _read(bin);
  final registered = veloraCommands.map((c) => c.name).toSet();

  final switchBody = source.substring(
    source.indexOf('switch (arguments.first)'),
    source.indexOf('default:'),
  );
  final parsed = RegExp(r"case '([^']+)':")
      .allMatches(switchBody)
      .map((m) => m.group(1)!)
      .toSet();
  for (final name in parsed.difference(registered)) {
    _fail('$bin: command `$name` is parsed but not in veloraCommands.');
  }
  for (final name in registered.difference(parsed)) {
    _fail('$bin: veloraCommands lists `$name` but main() does not parse it.');
  }

  // Any `velora <word>` / `velora_cli <word>` that looks like a command
  // (new, doctor, help, or anything with make/install) must be registered.
  // The CLI source is included because it holds the generated-app templates,
  // including the `.ai/` context files.
  final mention = RegExp(
    r'\bvelora(?:_cli)? ((?:make|install)(?::[a-z_]+)?|new|doctor)\b',
  );
  for (final file in [
    ...markdown,
    bin,
    'packages/velora_cli/lib/velora_cli.dart',
  ]) {
    for (final match in mention.allMatches(_read(file))) {
      if (!registered.contains(match.group(1))) {
        _fail('$file: mentions unknown command `velora ${match.group(1)}`.');
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Installable packages
// ---------------------------------------------------------------------------

void _checkPackages() {
  final nav = _read('mkdocs.yml');
  for (final pkg in veloraPackageCatalog.values) {
    if (!_exists('packages/${pkg.name}/pubspec.yaml')) {
      _fail('veloraPackageCatalog: packages/${pkg.name} does not exist.');
    }
    if (!_exists(pkg.docs)) {
      _fail('veloraPackageCatalog: ${pkg.name} docs page ${pkg.docs} missing.');
    } else if (!nav.contains(p.posix.relative(pkg.docs, from: 'docs'))) {
      _fail('mkdocs.yml: nav does not include ${pkg.docs}.');
    }
    if (!_exists('packages/${pkg.name}/README.md')) {
      _fail('packages/${pkg.name}: missing README.md.');
    }
  }
  for (final match in RegExp(
    r':\s*([\w/-]+\.md)\s*$',
    multiLine: true,
  ).allMatches(nav)) {
    if (!_exists('docs/${match.group(1)}')) {
      _fail('mkdocs.yml: nav entry docs/${match.group(1)} does not exist.');
    }
  }
}

// ---------------------------------------------------------------------------
// Claims that contradict shipped state
// ---------------------------------------------------------------------------

void _checkStaleClaims(_UiRegistry ui) {
  const files = [
    'docs/packages/ui.md',
    'docs/roadmap.md',
    'examples/velora_ui_gallery/README.md',
    'packages/velora_ui/README.md',
    'packages/velora_cli/lib/velora_cli.dart',
  ];
  final stale = RegExp(
    r'up next|future layer|not shipped yet|layer 1 only|layers? \d-\d\b',
    caseSensitive: false,
  );
  final layerRef = RegExp(r'\bLayers? (\d+)');
  for (final file in files) {
    if (!_exists(file)) continue;
    final content = _read(file);
    for (final match in stale.allMatches(content)) {
      _fail(
        '$file: "${match.group(0)}" reads as a stale roadmap claim; '
        'describe what ships (${ui.maxLayer} layers).',
      );
    }
    for (final match in layerRef.allMatches(content)) {
      if (int.parse(match.group(1)!) > ui.maxLayer) {
        _fail('$file: refers to ${match.group(0)}, which is not registered.');
      }
    }
  }
  // The gallery must show every component layer it claims to showcase.
  final gallery = _read('examples/velora_ui_gallery/README.md');
  for (final layer in ui.layers.where((l) => l.number > 1)) {
    if (!gallery.contains('Layer ${layer.number}')) {
      _fail(
        'examples/velora_ui_gallery/README.md: '
        'does not describe Layer ${layer.number} (${layer.title}).',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Links and documented paths
// ---------------------------------------------------------------------------

String _slug(String heading) {
  var text = heading
      .replaceAll(RegExp(r'`'), '')
      .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1)!)
      .toLowerCase()
      .trim();
  text = text.replaceAll(RegExp(r'[^\p{L}\p{N}\s_-]', unicode: true), '');
  return text.replaceAll(RegExp(r'\s'), '-');
}

Set<String> _anchors(String content) {
  final withoutCode = content.replaceAll(
    RegExp(r'^```.*?^```', multiLine: true, dotAll: true),
    '',
  );
  final seen = <String, int>{};
  final anchors = <String>{};
  for (final match in RegExp(
    r'^#{1,6}\s+(.+?)\s*#*$',
    multiLine: true,
  ).allMatches(withoutCode)) {
    final slug = _slug(match.group(1)!);
    final count = seen.update(slug, (n) => n + 1, ifAbsent: () => 0);
    anchors.add(count == 0 ? slug : '$slug-$count');
    // mkdocs collapses repeated hyphens; GitHub keeps them. Accept both.
    anchors.add(slug.replaceAll(RegExp(r'-{2,}'), '-'));
  }
  return anchors;
}

void _checkLinksAndPaths(List<String> markdown) {
  final link = RegExp(r'(?<!\!)\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)');
  final path = RegExp(
    r'`((?:packages|examples|docs|tool|\.github)/[\w./-]*[\w/])`',
  );
  final fence = RegExp(r'^```.*?^```', multiLine: true, dotAll: true);

  for (final file in markdown) {
    final content = _read(file).replaceAll(fence, '');
    final dir = p.posix.dirname(file);

    for (final match in link.allMatches(content)) {
      final target = match.group(1)!;
      if (RegExp(r'^[a-z][a-z0-9+.-]*:').hasMatch(target)) continue;
      // Directory-style links (../api/, ../demo/) point at pages the docs
      // site build produces, not at files in this repository.
      if (target.endsWith('/')) continue;
      final hash = target.indexOf('#');
      final rawPath = hash == -1 ? target : target.substring(0, hash);
      final anchor = hash == -1 ? '' : target.substring(hash + 1);
      final resolved = rawPath.isEmpty
          ? file
          : p.posix.normalize(p.posix.join(dir, rawPath));
      if (!_exists(resolved)) {
        _fail('$file: broken link $target');
        continue;
      }
      if (anchor.isNotEmpty && resolved.endsWith('.md')) {
        if (!_anchors(_read(resolved)).contains(anchor.toLowerCase())) {
          _fail('$file: link $target points at a missing heading.');
        }
      }
    }

    for (final match in path.allMatches(content)) {
      final documented = match.group(1)!;
      if (documented.contains('*') || documented.contains('<')) continue;
      // `docs/…` directories can also be a generated app's own (for
      // example `docs/reminders/`), so only files are checked there.
      if (documented.startsWith('docs/') && p.extension(documented).isEmpty) {
        continue;
      }
      if (!_exists(documented)) {
        _fail('$file: documented path `$documented` does not exist.');
      }
    }
  }
}

// ---------------------------------------------------------------------------
// SDK baseline and historical planning documents
// ---------------------------------------------------------------------------

void _checkBaselineAndHistory() {
  final toolchain = _read('docs/toolchain.md');
  for (final (tool, version) in [
    ('Flutter', veloraMinFlutterVersion),
    ('Dart', veloraMinDartVersion),
  ]) {
    if (!toolchain.contains('| $tool | $version |')) {
      _fail('docs/toolchain.md: baseline table must list $tool $version.');
    }
  }
  final baseline = _read('tool/check_baseline.sh');
  if (!baseline.contains('MIN_DART="$veloraMinDartVersion"') ||
      !baseline.contains('MIN_FLUTTER="$veloraMinFlutterVersion"')) {
    _fail('tool/check_baseline.sh: minimums differ from velora_cli constants.');
  }
  for (final file in ['velora.md', 'velora.part2.md']) {
    final head = LineSplitter.split(_read(file)).take(12).join('\n');
    if (!head.toLowerCase().contains('historical')) {
      _fail('$file: must open with a "historical planning document" banner.');
    }
  }
}
