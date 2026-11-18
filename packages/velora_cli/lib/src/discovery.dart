/// Version-aware lookup behind `velora manifest`, `search`, `component`, and
/// `docs`: project resolution, registries, JSON envelopes, and error codes.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../velora_cli.dart';

/// Version of the JSON envelope every `--json` command prints. Bumped only
/// for a breaking change to the envelope or to a documented `data` shape.
const veloraApiVersion = 1;

/// A stable, machine-readable failure code. Integrations branch on [code],
/// never on the message text.
class VeloraErrorCode {
  final String code;

  /// When the CLI reports this code, used in generated docs.
  final String meaning;

  const VeloraErrorCode(this.code, this.meaning);

  static const unknownCommand = VeloraErrorCode(
    'ERR_UNKNOWN_COMMAND',
    'The first argument is not a Velora command.',
  );
  static const unknownComponent = VeloraErrorCode(
    'ERR_UNKNOWN_COMPONENT',
    'No `velora_ui` export has that name in the installed version.',
  );
  static const unknownDocsTopic = VeloraErrorCode(
    'ERR_UNKNOWN_DOCS_TOPIC',
    'No documentation topic has that id.',
  );
  static const invalidArgument = VeloraErrorCode(
    'ERR_INVALID_ARGUMENT',
    'A required argument is missing, or an option or its value is not '
        'accepted.',
  );
  static const projectRequired = VeloraErrorCode(
    'ERR_PROJECT_REQUIRED',
    'The command needs a resolved Dart project: a `pubspec.yaml` and '
        '`.dart_tool/package_config.json` in the current directory or a '
        'parent.',
  );
  static const packageNotInstalled = VeloraErrorCode(
    'ERR_PACKAGE_NOT_INSTALLED',
    'The project does not resolve the package the answer comes from.',
  );
  static const invalidRegistry = VeloraErrorCode(
    'ERR_INVALID_REGISTRY',
    'The installed package\'s registry or a registered source file is '
        'missing or malformed.',
  );

  /// Every code the CLI can report.
  static const all = <VeloraErrorCode>[
    unknownCommand,
    unknownComponent,
    unknownDocsTopic,
    invalidArgument,
    projectRequired,
    packageNotInstalled,
    invalidRegistry,
  ];
}

/// A suggested alternative attached to an error.
class VeloraSuggestion {
  final String name;
  final String reason;

  const VeloraSuggestion(this.name, this.reason);

  Map<String, Object?> toJson() => {'name': name, 'reason': reason};
}

/// A failure with a stable [code], thrown by the discovery commands.
class VeloraCliError implements Exception {
  final VeloraErrorCode code;
  final String message;
  final List<VeloraSuggestion> suggestions;

  const VeloraCliError(this.code, this.message, {this.suggestions = const []});

  @override
  String toString() => '${code.code}: $message';
}

/// Every `type` a successful `--json` envelope can carry.
const veloraOutputTypes = <String>[
  'manifest',
  'search.results',
  'component.list',
  'component.detail',
  'docs.list',
  'docs.page',
];

/// A documentation page `velora docs <topic>` can serve.
class VeloraDocsTopic {
  final String id;
  final String title;

  /// Repo-relative path of the page.
  final String path;

  const VeloraDocsTopic(this.id, this.title, this.path);

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'path': path};
}

/// Topics served by `velora docs`, in listing order.
const veloraDocsTopics = <VeloraDocsTopic>[
  VeloraDocsTopic(
    'getting-started',
    'Install and boot',
    'docs/getting-started.md',
  ),
  VeloraDocsTopic(
    'architecture',
    'Architecture, state ownership, and GetX',
    'docs/architecture.md',
  ),
  VeloraDocsTopic(
    'boundary',
    'Framework / app boundary',
    'docs/framework-app-boundary.md',
  ),
  VeloraDocsTopic('auth', 'Auth and logout safety', 'docs/auth.md'),
  VeloraDocsTopic('api-client', 'API client', 'docs/api-client.md'),
  VeloraDocsTopic('permissions', 'Permissions', 'docs/permissions.md'),
  VeloraDocsTopic('notifications', 'Notifications', 'docs/notifications.md'),
  VeloraDocsTopic('scaffolding', 'Generated modules', 'docs/scaffolding.md'),
  VeloraDocsTopic(
    'plugins',
    'Plugins and package authoring',
    'docs/plugins.md',
  ),
  VeloraDocsTopic('pwa', 'Web and PWA', 'docs/pwa.md'),
  VeloraDocsTopic('offline', 'Offline data', 'docs/packages/offline.md'),
  VeloraDocsTopic('db', 'Local database', 'docs/packages/db.md'),
  VeloraDocsTopic('env', 'Environment config', 'docs/packages/env.md'),
  VeloraDocsTopic(
    'ui',
    'Theming, components, accessibility, and responsive layout',
    'docs/packages/ui.md',
  ),
  VeloraDocsTopic('commands', 'CLI commands', 'docs/commands.md'),
  VeloraDocsTopic(
    'agents',
    'Agent tooling and JSON contracts',
    'docs/agent-tooling.md',
  ),
  VeloraDocsTopic(
    'desktop',
    'Desktop lifecycle: close-to-tray, single instance, auto-start',
    'docs/packages/desktop.md',
  ),
  VeloraDocsTopic('toolchain', 'Toolchain baseline', 'docs/toolchain.md'),
];

/// Where the hosted documentation lives. It describes the latest version,
/// which may differ from the packages a project has installed.
const veloraDocsSiteUrl = 'https://md-riaz.github.io/velora-flutter/';

/// A package the current project resolves.
class VeloraResolvedPackage {
  final String name;

  /// Absolute path of the package root.
  final String root;

  /// The `version:` in the package's own `pubspec.yaml`, if readable.
  final String? version;

  const VeloraResolvedPackage(this.name, this.root, this.version);
}

/// The Dart project a command runs in, as resolved by `pub get`.
class VeloraProject {
  /// Directory holding the project's `pubspec.yaml`.
  final String root;

  /// Every resolved package, by name.
  final Map<String, VeloraResolvedPackage> packages;

  const VeloraProject(this.root, this.packages);

  /// Whether [name] is a package from the Velora repository (as opposed to
  /// the app itself or a third-party package that happens to share the
  /// prefix).
  static bool isVeloraPackage(String name) =>
      name == 'velora' ||
      name == 'velora_cli' ||
      name == 'velora_lints' ||
      veloraPackageCatalog.containsKey(name);

  /// Resolved Velora packages and their versions.
  Map<String, String?> get veloraVersions => {
    for (final pkg in packages.values)
      if (isVeloraPackage(pkg.name)) pkg.name: pkg.version,
  };

  /// Absolute path of the documentation page at repo-relative [path], or
  /// `null` when the installed packages do not carry the docs. Path and git
  /// dependencies check out the whole repository, so `docs/` sits two levels
  /// above each package; a hosted package does not include it.
  String? docsFile(String path) {
    for (final pkg in packages.values) {
      if (!isVeloraPackage(pkg.name)) continue;
      final file = File(p.normalize(p.join(pkg.root, '..', '..', path)));
      if (file.existsSync()) return file.path;
    }
    return null;
  }

  /// Finds the project containing [start]: the nearest `pubspec.yaml`, and
  /// the nearest `.dart_tool/package_config.json` at or above it (a pub
  /// workspace keeps one at the workspace root). Returns `null` when there is
  /// no `pubspec.yaml`; throws [VeloraCliError] when the project has not been
  /// resolved or its package config is unreadable.
  static VeloraProject? find(String start) {
    String? root;
    String? config;
    var dir = p.normalize(p.absolute(start));
    while (true) {
      if (root == null && File(p.join(dir, 'pubspec.yaml')).existsSync()) {
        root = dir;
      }
      if (root != null) {
        final candidate = p.join(dir, '.dart_tool', 'package_config.json');
        if (File(candidate).existsSync()) {
          config = candidate;
          break;
        }
      }
      final parent = p.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }
    if (root == null) return null;
    if (config == null) {
      throw VeloraCliError(
        VeloraErrorCode.projectRequired,
        'No .dart_tool/package_config.json for $root. '
        'Run `flutter pub get` first.',
      );
    }

    final packages = <String, VeloraResolvedPackage>{};
    try {
      final json = jsonDecode(File(config).readAsStringSync()) as Map;
      final base = Uri.directory(p.dirname(config));
      for (final entry in (json['packages'] as List).cast<Map>()) {
        final name = entry['name'] as String;
        var rootUri = entry['rootUri'] as String;
        if (!rootUri.endsWith('/')) rootUri = '$rootUri/';
        final pkgRoot = p.normalize(base.resolve(rootUri).toFilePath());
        packages[name] = VeloraResolvedPackage(
          name,
          pkgRoot,
          _pubspecVersion(pkgRoot),
        );
      }
    } on Object catch (error) {
      throw VeloraCliError(
        VeloraErrorCode.projectRequired,
        'Could not read $config ($error). Run `flutter pub get` again.',
      );
    }
    return VeloraProject(root, packages);
  }
}

String? _pubspecVersion(String packageRoot) {
  final file = File(p.join(packageRoot, 'pubspec.yaml'));
  if (!file.existsSync()) return null;
  return RegExp(
    r'^version:\s*(\S+)',
    multiLine: true,
  ).firstMatch(file.readAsStringSync())?.group(1);
}

/// The `meta` object of a JSON envelope: which versions produced the answer.
Map<String, Object?> veloraAnswerMeta(VeloraProject? project) => {
  'answeredBy': {
    'cli': veloraCliVersion,
    'project': project != null,
    'packages': project?.veloraVersions ?? <String, String?>{},
  },
};

/// A successful JSON envelope.
Map<String, Object?> veloraEnvelope(
  String type,
  Object? data,
  VeloraProject? project,
) {
  assert(veloraOutputTypes.contains(type), 'unregistered output type $type');
  return {
    'apiVersion': veloraApiVersion,
    'type': type,
    'data': data,
    'meta': veloraAnswerMeta(project),
  };
}

/// A failed JSON envelope.
Map<String, Object?> veloraErrorEnvelope(VeloraCliError error) => {
  'apiVersion': veloraApiVersion,
  'error': error.message,
  'code': error.code.code,
  'suggestions': [for (final s in error.suggestions) s.toJson()],
};

/// One `velora_ui` export registered in the installed `components.json`.
class VeloraComponent {
  final String name;

  /// Path of the declaring file, relative to the package's `lib/`.
  final String file;
  final int layer;
  final String category;

  const VeloraComponent(this.name, this.file, this.layer, this.category);
}

/// The installed `velora_ui`: its registry and declaration sources.
class VeloraUiCatalog {
  final VeloraResolvedPackage package;
  final List<VeloraComponent> components;
  final Map<String, String> _sources = {};

  VeloraUiCatalog._(this.package, this.components);

  static const importLine = "import 'package:velora_ui/velora_ui.dart';";

  /// Loads the registry of the `velora_ui` that [project] resolves.
  static VeloraUiCatalog load(VeloraProject? project) {
    if (project == null) {
      throw const VeloraCliError(
        VeloraErrorCode.projectRequired,
        'Run this inside a Flutter project so the answer matches its '
        'installed velora_ui.',
      );
    }
    final package = project.packages['velora_ui'];
    if (package == null) {
      throw const VeloraCliError(
        VeloraErrorCode.packageNotInstalled,
        'This project does not depend on velora_ui. '
        'Add it with `velora install velora_ui`, then run `flutter pub get`.',
      );
    }
    final file = File(p.join(package.root, 'components.json'));
    if (!file.existsSync()) {
      throw VeloraCliError(
        VeloraErrorCode.invalidRegistry,
        'The installed velora_ui ${package.version ?? ''} has no '
        'components.json (${file.path}).',
      );
    }
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map;
      final components = <VeloraComponent>[
        for (final layer in (json['layers'] as List).cast<Map>())
          for (final c in (layer['components'] as List).cast<Map>())
            VeloraComponent(
              c['name'] as String,
              c['file'] as String,
              layer['layer'] as int,
              layer['title'] as String,
            ),
      ];
      return VeloraUiCatalog._(package, components);
    } on Object catch (error) {
      throw VeloraCliError(
        VeloraErrorCode.invalidRegistry,
        '${file.path} is malformed: $error',
      );
    }
  }

  /// The component named [name], matched case-insensitively and with or
  /// without the `Velora` prefix.
  VeloraComponent find(String name) {
    final wanted = _normalize(name);
    for (final c in components) {
      final n = _normalize(c.name);
      if (n == wanted || n == 'velora$wanted') return c;
    }
    throw VeloraCliError(
      VeloraErrorCode.unknownComponent,
      'No component named $name in velora_ui ${package.version ?? ''}'
          .trimRight(),
      suggestions: suggestNames(name, components.map((c) => c.name)),
    );
  }

  /// Absolute path of the file declaring [component].
  String sourcePath(VeloraComponent component) =>
      p.join(package.root, 'lib', component.file);

  /// The parsed declaration of [component].
  DartDeclaration declaration(VeloraComponent component) {
    final path = sourcePath(component);
    final source = _sources.putIfAbsent(path, () {
      final file = File(path);
      if (!file.existsSync()) {
        throw VeloraCliError(
          VeloraErrorCode.invalidRegistry,
          'components.json registers ${component.name} in '
          '${component.file}, which the installed velora_ui does not have.',
        );
      }
      return file.readAsStringSync();
    });
    final declaration = scanDeclaration(source, component.name);
    if (declaration == null) {
      throw VeloraCliError(
        VeloraErrorCode.invalidRegistry,
        '${component.file} does not declare ${component.name}.',
      );
    }
    return declaration;
  }

  /// One-line entry for listings and search.
  Map<String, Object?> brief(VeloraComponent component) => {
    'name': component.name,
    'kind': declaration(component).kind,
    'category': component.category,
    'summary': declaration(component).summary,
  };

  /// Full description of [component]. With [full] false, per-parameter and
  /// per-value documentation and the long description are left out.
  Map<String, Object?> detail(VeloraComponent component, {bool full = true}) {
    final d = declaration(component);
    return {
      'name': component.name,
      'kind': d.kind,
      'package': 'velora_ui',
      'import': importLine,
      'layer': component.layer,
      'category': component.category,
      'source': p.posix.join('lib', component.file),
      'summary': d.summary,
      if (full) 'documentation': d.documentation,
      if (d.on != null) 'on': d.on,
      if (d.constructors.isNotEmpty)
        'constructors': [for (final c in d.constructors) c.toJson(full: full)],
      if (d.signature != null) 'function': d.signature!.toJson(full: full),
      if (d.staticMethods.isNotEmpty)
        'staticMethods': [
          for (final m in d.staticMethods) m.toJson(full: full),
        ],
      if (d.values.isNotEmpty)
        'values': [
          for (final v in d.values)
            {'name': v.name, if (full) 'documentation': v.documentation},
        ],
      if (d.members.isNotEmpty) 'members': d.members,
    };
  }
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

List<String> _tokens(String value) => value
    .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
    .toLowerCase()
    .split(RegExp('[^a-z0-9]+'))
    .where((t) => t.isNotEmpty)
    .toList();

int _editDistance(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, i);
    for (var j = 1; j <= b.length; j++) {
      final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
      final insertion = current[j - 1] + 1;
      final deletion = previous[j] + 1;
      current[j] = [
        substitution,
        insertion,
        deletion,
      ].reduce((x, y) => x < y ? x : y);
    }
    previous = current;
  }
  return previous[b.length];
}

/// How well [name] matches [query] by name alone: 100 exact, 90 prefix, 80
/// substring, 70 every query word present, 30 a likely misspelling, 0 none.
/// A leading `velora` is ignored on both sides.
int _nameScore(String query, String name) {
  String strip(String s) =>
      s.startsWith('velora') && s.length > 6 ? s.substring(6) : s;
  final q = strip(_normalize(query));
  final n = strip(_normalize(name));
  if (q.isEmpty || n.isEmpty) return 0;
  if (n == q) return 100;
  if (n.startsWith(q)) return 90;
  if (n.contains(q)) return 80;
  final words = _tokens(query).where((t) => t != 'velora').toList();
  if (words.length > 1 && words.every(n.contains)) return 70;
  final allowed = q.length <= 4 ? 1 : (q.length <= 8 ? 2 : 3);
  if (_editDistance(q, n) <= allowed) return 30;
  return 0;
}

/// Up to [limit] of [candidates] that [name] most likely meant.
List<VeloraSuggestion> suggestNames(
  String name,
  Iterable<String> candidates, {
  int limit = 3,
}) {
  final scored = <(int, String)>[
    for (final c in candidates)
      if (_nameScore(name, c) > 0) (_nameScore(name, c), c),
  ]..sort((a, b) => b.$1 != a.$1 ? b.$1.compareTo(a.$1) : a.$2.compareTo(b.$2));
  return [
    for (final (score, candidate) in scored.take(limit))
      VeloraSuggestion(candidate, score >= 80 ? 'name match' : 'similar name'),
  ];
}

/// The kinds of entry `velora search` covers, as accepted by `--type`.
const veloraSearchTypes = <String>['component', 'docs', 'package', 'command'];

/// One search result.
class VeloraSearchHit {
  final String type;
  final String name;
  final String summary;
  final int score;

  /// `name` when the name matched, `description` when only the summary did,
  /// `similar name` for a likely misspelling.
  final String reason;

  const VeloraSearchHit(
    this.type,
    this.name,
    this.summary,
    this.score,
    this.reason,
  );

  Map<String, Object?> toJson() => {
    'type': type,
    'name': name,
    'summary': summary,
    'score': score,
    'reason': reason,
  };
}

/// Searches components (when [catalog] is given), docs topics, installable
/// packages, and commands. Results are ordered by score, then name.
List<VeloraSearchHit> veloraSearch(
  String query, {
  VeloraUiCatalog? catalog,
  Set<String>? types,
  int limit = 10,
}) {
  final words = _tokens(query).where((t) => t != 'velora').toList();
  final hits = <VeloraSearchHit>[];

  void consider(String type, String name, String summary, [String extra = '']) {
    if (types != null && !types.contains(type)) return;
    var score = _nameScore(query, name);
    var reason = score == 30 ? 'similar name' : 'name';
    if (score < 70 && words.isNotEmpty) {
      final text = '$summary $extra'.toLowerCase();
      if (words.every(text.contains)) {
        score = 40;
        reason = 'description';
      }
    }
    if (score > 0) {
      hits.add(VeloraSearchHit(type, name, summary, score, reason));
    }
  }

  if (catalog != null) {
    for (final c in catalog.components) {
      consider('component', c.name, catalog.declaration(c).summary, c.category);
    }
  }
  for (final topic in veloraDocsTopics) {
    consider('docs', topic.id, topic.title);
  }
  for (final pkg in veloraPackageCatalog.values) {
    consider('package', pkg.name, pkg.summary);
  }
  for (final command in veloraCommands) {
    consider('command', command.name, command.summary);
  }

  hits.sort(
    (a, b) => b.score != a.score
        ? b.score.compareTo(a.score)
        : a.name.compareTo(b.name),
  );
  return hits.take(limit).toList();
}

/// The `data` of `velora manifest --json`.
Map<String, Object?> veloraManifest({VeloraUiCatalog? catalog}) => {
  'cli': {'name': veloraCliName, 'version': veloraCliVersion},
  'apiVersion': veloraApiVersion,
  'minimumSdk': {
    'dart': veloraMinDartVersion,
    'flutter': veloraMinFlutterVersion,
  },
  'commands': [
    for (final c in veloraCommands)
      {
        'name': c.name,
        'arguments': c.arguments,
        'usage': c.usage,
        'summary': c.summary,
        'json': c.json,
      },
  ],
  'packages': [
    for (final pkg in veloraPackageCatalog.values)
      {
        'name': pkg.name,
        'constraint': pkg.constraint,
        'summary': pkg.summary,
        'autoWired': pkg.wiresPlugin,
        'docs': pkg.docs,
      },
  ],
  'docsTopics': [for (final t in veloraDocsTopics) t.toJson()],
  'counts': {
    'components': catalog?.components.length,
    'docsTopics': veloraDocsTopics.length,
    'packages': veloraPackageCatalog.length,
    'commands': veloraCommands.length,
  },
  'outputTypes': veloraOutputTypes,
  'errorCodes': [
    for (final e in VeloraErrorCode.all) {'code': e.code, 'meaning': e.meaning},
  ],
};

const veloraAgentsStartMarker = '<!-- velora:agents:start -->';
const veloraAgentsEndMarker = '<!-- velora:agents:end -->';

/// The managed block `velora make:agents` keeps in a project's `AGENTS.md`.
/// It points at the lookup commands instead of copying the catalog, so it
/// does not go stale when packages are upgraded.
String veloraAgentsSection() =>
    '''
$veloraAgentsStartMarker
## Velora

This app uses Velora. Look things up from the installed version instead of guessing:

- `dart run velora_cli search <query>` finds components, docs, packages, and commands. Search before writing a new widget.
- `dart run velora_cli component <Name>` prints a component's constructor parameters and docs. Read it before using an unfamiliar API; do not guess parameters.
- `dart run velora_cli docs <topic>` prints a guide. Read `architecture` and `boundary` before moving code between layers.
- `dart run velora_cli doctor` checks wiring and the SDK baseline.
- Add `--json` to `search`, `component`, `docs`, or `manifest` for a versioned envelope. Branch on the error `code`, not the message.

Rules:

- Domain models, routes, endpoints, permissions, copy, and brand stay in the app.
- `velora_ui` components are controlled: the caller owns values and callbacks.
- UI permission checks are not backend authorization.
- No secrets in this file or in `.ai/`.
- After a change run `dart format .`, `flutter analyze`, and the tests for what you touched.
$veloraAgentsEndMarker
''';

/// Returns [existing] with the managed block inserted or replaced. Text
/// outside the markers is kept byte for byte.
String upsertVeloraAgentsSection(String existing) {
  final section = veloraAgentsSection().trimRight();
  final start = existing.indexOf(veloraAgentsStartMarker);
  final end = existing.indexOf(veloraAgentsEndMarker);
  if (start >= 0 && end > start) {
    return existing.replaceRange(
      start,
      end + veloraAgentsEndMarker.length,
      section,
    );
  }
  if (existing.trim().isEmpty) return '# AGENTS.md\n\n$section\n';
  final separator = existing.endsWith('\n') ? '\n' : '\n\n';
  return '$existing$separator$section\n';
}

/// Whether [content] holds a managed block that differs from the one this
/// CLI version writes. `false` when there is no block at all.
bool veloraAgentsSectionIsStale(String content) {
  final start = content.indexOf(veloraAgentsStartMarker);
  final end = content.indexOf(veloraAgentsEndMarker);
  if (start < 0 || end < start) return false;
  return content.substring(start, end + veloraAgentsEndMarker.length) !=
      veloraAgentsSection().trimRight();
}
