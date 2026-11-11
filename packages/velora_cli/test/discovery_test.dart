import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:velora_cli/velora_cli.dart';

/// Creates a project whose package config resolves [packages] (name → root).
Directory _project(Map<String, String> packages) {
  final dir = Directory.systemTemp.createTempSync('velora_cli_discovery_');
  addTearDown(() => dir.deleteSync(recursive: true));
  File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync('name: sample\n');
  File(p.join(dir.path, '.dart_tool', 'package_config.json'))
    ..createSync(recursive: true)
    ..writeAsStringSync(
      jsonEncode({
        'configVersion': 2,
        'packages': [
          for (final entry in packages.entries)
            {
              'name': entry.key,
              'rootUri': Uri.directory(entry.value).toString(),
              'packageUri': 'lib/',
            },
        ],
      }),
    );
  return dir;
}

/// The package root, independent of the working directory (other test files
/// in this process change it).
final _cliRoot = p.dirname(
  p.dirname(
    Isolate.resolvePackageUriSync(
      Uri.parse('package:velora_cli/velora_cli.dart'),
    )!.toFilePath(),
  ),
);
final _repoPackages = p.dirname(_cliRoot);

Directory _realProject() => _project({
  'velora': p.join(_repoPackages, 'velora'),
  'velora_ui': p.join(_repoPackages, 'velora_ui'),
});

/// A stand-in `velora_ui` at another version with a different API.
String _fakeUi() {
  final dir = Directory.systemTemp.createTempSync('velora_ui_fake_');
  addTearDown(() => dir.deleteSync(recursive: true));
  File(p.join(dir.path, 'pubspec.yaml'))
      .writeAsStringSync('name: velora_ui\nversion: 9.9.9\n');
  File(p.join(dir.path, 'components.json')).writeAsStringSync(
    jsonEncode({
      'layers': [
        {
          'layer': 1,
          'title': 'Fake',
          'components': [
            {'name': 'VeloraButton', 'file': 'src/button.dart'},
          ],
        },
      ],
    }),
  );
  File(p.join(dir.path, 'lib', 'src', 'button.dart'))
    ..createSync(recursive: true)
    ..writeAsStringSync('''
/// A button from another version.
class VeloraButton {
  /// The text.
  final String caption;

  const VeloraButton({required this.caption});
}
''');
  return dir.path;
}

Future<ProcessResult> _cli(Directory cwd, List<String> args) => Process.run(
  Platform.resolvedExecutable,
  [p.join(_cliRoot, 'bin', 'velora_cli.dart'), ...args],
  workingDirectory: cwd.path,
);

Map<String, Object?> _json(ProcessResult result) =>
    jsonDecode(result.stdout as String) as Map<String, Object?>;

void main() {
  group('source scanner', () {
    test('reads constructor parameters, defaults, and field docs', () {
      final d = scanDeclaration('''
/// A thing.
///
/// More detail, with a brace } and a quote ' in the comment.
@immutable
class Thing<T> extends Base {
  /// The label.
  final String label;

  /// Items, keyed.
  final Map<String, List<T>> items;
  final void Function(T value, {bool force})? onChanged;
  static const fallback = Thing(label: 'x');

  const Thing({
    super.key,
    required this.label,
    this.items = const {},
    this.onChanged,
    @Deprecated('use label') String? title = 'a, b',
  });

  Thing.named(int count, [String note = '']) : this(label: '\$count\${note}');
  Thing._private() : this(label: '');

  /// Builds one.
  static Future<T?> show<T>(BuildContext context, {bool modal = true}) async {
    return null;
  }

  Widget build() => Thing(label: label);
}
''', 'Thing')!;
      expect(d.kind, 'class');
      expect(d.summary, 'A thing.');
      expect(d.constructors.map((c) => c.name), ['Thing', 'Thing.named']);

      final main = d.constructors.first;
      expect(main.isConst, isTrue);
      expect(main.parameters.map((x) => x.name), [
        'key',
        'label',
        'items',
        'onChanged',
        'title',
      ]);
      final label = main.parameters[1];
      expect(label.type, 'String');
      expect(label.isRequired, isTrue);
      expect(label.kind, 'named');
      expect(label.documentation, 'The label.');
      expect(main.parameters[0].type, 'Key?');
      expect(main.parameters[2].type, 'Map<String, List<T>>');
      expect(main.parameters[2].defaultValue, 'const {}');
      expect(main.parameters[3].type, 'void Function(T value, {bool force})?');
      expect(main.parameters[4].type, 'String?');
      expect(main.parameters[4].defaultValue, "'a, b'");

      final named = d.constructors.last;
      expect(named.parameters.map((x) => '${x.kind} ${x.type} ${x.name}'), [
        'positional int count',
        'optionalPositional String note',
      ]);

      expect(d.staticMethods.single.name, 'show');
      expect(d.staticMethods.single.returnType, 'Future<T?>');
      expect(d.staticMethods.single.documentation, 'Builds one.');
      expect(d.staticMethods.single.parameters.map((x) => x.name), [
        'context',
        'modal',
      ]);
    });

    test('reads enums, extensions, functions, and typedefs', () {
      const source = '''
/// Sizes.
enum Size {
  /// Small, compact.
  small,
  large(2);

  const Size([this.scale = 1]);
  final int scale;
}

/// Helpers.
extension Tokens on BuildContext {
  /// The tokens.
  int get tokens => 1;
  int _hidden() => 2;
}

/// Builds a theme.
ThemeData buildTheme({required Brightness brightness, String? font}) {
  return ThemeData();
}

/// A callback.
typedef Callback = void Function(int);
''';
      final size = scanDeclaration(source, 'Size')!;
      expect(size.kind, 'enum');
      expect(size.values.map((v) => v.name), ['small', 'large']);
      expect(size.values.first.documentation, 'Small, compact.');

      final tokens = scanDeclaration(source, 'Tokens')!;
      expect(tokens.kind, 'extension');
      expect(tokens.on, 'BuildContext');
      expect(tokens.members, ['tokens']);

      final build = scanDeclaration(source, 'buildTheme')!;
      expect(build.kind, 'function');
      expect(build.signature!.returnType, 'ThemeData');
      expect(build.signature!.parameters.map((x) => x.name), [
        'brightness',
        'font',
      ]);

      expect(scanDeclaration(source, 'Callback')!.kind, 'typedef');
      expect(scanDeclaration(source, 'Missing'), isNull);
    });
  });

  group('installed velora_ui', () {
    test('every registered component is described with typed parameters', () {
      final project = VeloraProject.find(_realProject().path);
      final catalog = VeloraUiCatalog.load(project);
      expect(catalog.components, isNotEmpty);
      for (final component in catalog.components) {
        final d = catalog.declaration(component);
        expect(d.summary, isNotEmpty, reason: component.name);
        final signatures = [
          ...d.constructors,
          ...d.staticMethods,
          if (d.signature != null) d.signature!,
        ];
        for (final signature in signatures) {
          for (final parameter in signature.parameters) {
            expect(
              parameter.type,
              isNotNull,
              reason: '${component.name}: ${signature.name}.${parameter.name}',
            );
          }
        }
        if (d.kind == 'enum') {
          expect(d.values, isNotEmpty, reason: component.name);
        }
        if (d.kind == 'class') {
          expect(
            d.constructors.isNotEmpty || d.staticMethods.isNotEmpty,
            isTrue,
            reason: component.name,
          );
        }
      }
    });

    test('find ignores case and the Velora prefix, and suggests', () {
      final catalog = VeloraUiCatalog.load(
        VeloraProject.find(_realProject().path),
      );
      expect(catalog.find('datatable').name, 'VeloraDataTable');
      expect(catalog.find('velorabutton').name, 'VeloraButton');
      expect(
        () => catalog.find('VeloraDatTable'),
        throwsA(
          isA<VeloraCliError>()
              .having((e) => e.code, 'code', VeloraErrorCode.unknownComponent)
              .having(
                (e) => e.suggestions.map((s) => s.name),
                'suggestions',
                contains('VeloraDataTable'),
              ),
        ),
      );
    });

    test('search ranks names over descriptions and covers every kind', () {
      final catalog = VeloraUiCatalog.load(
        VeloraProject.find(_realProject().path),
      );
      final table = veloraSearch('data-table', catalog: catalog);
      expect(table.first.name, 'VeloraDataTable');
      expect(table.first.type, 'component');

      expect(
        veloraSearch('buton', catalog: catalog).single.reason,
        'similar name',
      );
      expect(
        veloraSearch('offline').map((h) => '${h.type}:${h.name}'),
        containsAll(['package:velora_offline', 'docs:offline']),
      );
      expect(veloraSearch('doctor', types: {'command'}).single.name, 'doctor');
      expect(veloraSearch('zzzz', catalog: catalog), isEmpty);
    });
  });

  group('project resolution', () {
    test('no pubspec means no project', () {
      final dir = Directory.systemTemp.createTempSync('velora_cli_none_');
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(VeloraProject.find(dir.path), isNull);
      expect(
        () => VeloraUiCatalog.load(null),
        throwsA(
          isA<VeloraCliError>().having(
            (e) => e.code,
            'code',
            VeloraErrorCode.projectRequired,
          ),
        ),
      );
    });

    test(
      'an unresolved project and a missing package have their own codes',
      () {
        final dir = Directory.systemTemp.createTempSync('velora_cli_unres_');
        addTearDown(() => dir.deleteSync(recursive: true));
        File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync('name: x\n');
        expect(
          () => VeloraProject.find(dir.path),
          throwsA(
            isA<VeloraCliError>().having(
              (e) => e.code,
              'code',
              VeloraErrorCode.projectRequired,
            ),
          ),
        );

        final withoutUi = VeloraProject.find(
          _project({'velora': p.join(_repoPackages, 'velora')}).path,
        );
        expect(
          () => VeloraUiCatalog.load(withoutUi),
          throwsA(
            isA<VeloraCliError>().having(
              (e) => e.code,
              'code',
              VeloraErrorCode.packageNotInstalled,
            ),
          ),
        );
      },
    );

    test('found from a subdirectory; reports only Velora packages', () {
      final dir = _project({
        'velora_ui': p.join(_repoPackages, 'velora_ui'),
        'velora_sample_app': p.join(_repoPackages, 'velora_cli'),
        'path': p.join(_repoPackages, 'velora_cli'),
      });
      final nested = Directory(p.join(dir.path, 'lib', 'src'))
        ..createSync(recursive: true);
      final project = VeloraProject.find(nested.path)!;
      expect(p.equals(project.root, dir.path), isTrue);
      expect(project.veloraVersions.keys, ['velora_ui']);
      expect(project.veloraVersions['velora_ui'], isNotNull);
    });
  });

  group('registries', () {
    test('ids, codes, and output types are unique', () {
      final topics = veloraDocsTopics.map((t) => t.id).toList();
      expect(topics.toSet().length, topics.length);
      final codes = VeloraErrorCode.all.map((e) => e.code).toList();
      expect(codes.toSet().length, codes.length);
      expect(codes.every((c) => c.startsWith('ERR_')), isTrue);
      expect(veloraOutputTypes.toSet().length, veloraOutputTypes.length);
    });

    test('every command that claims JSON documents the flag', () {
      for (final command in veloraCommands) {
        expect(
          command.arguments.contains('--json'),
          command.json,
          reason: command.name,
        );
      }
    });
  });

  group('managed AGENTS.md section', () {
    test('is created, appended, replaced in place, and detected as stale', () {
      final fresh = upsertVeloraAgentsSection('');
      expect(fresh, startsWith('# AGENTS.md\n'));
      expect(veloraAgentsSectionIsStale(fresh), isFalse);
      expect(upsertVeloraAgentsSection(fresh), fresh);

      const mine = '# Rules\n\nKeep my notes.\n';
      final appended = upsertVeloraAgentsSection(mine);
      expect(appended, startsWith(mine));
      expect(appended, contains(veloraAgentsStartMarker));

      final old =
          '$mine\n$veloraAgentsStartMarker\nold text\n'
          '$veloraAgentsEndMarker\n\n## After\n';
      expect(veloraAgentsSectionIsStale(old), isTrue);
      final refreshed = upsertVeloraAgentsSection(old);
      expect(refreshed, startsWith(mine));
      expect(refreshed, endsWith('\n\n## After\n'));
      expect(refreshed, isNot(contains('old text')));
      expect(veloraAgentsSectionIsStale(refreshed), isFalse);
      expect(veloraAgentsSectionIsStale(mine), isFalse);
    });

    test('names only commands that exist', () {
      final names = veloraCommands.map((c) => c.name).toSet();
      final mentioned = RegExp(r'velora_cli ([a-z:]+)')
          .allMatches(veloraAgentsSection())
          .map((m) => m.group(1)!);
      expect(mentioned, isNotEmpty);
      expect(names, containsAll(mentioned));
    });
  });

  group('commands', () {
    test('component --json answers from the installed version', () async {
      final real = await _cli(_realProject(), [
        'component',
        'VeloraButton',
        '--json',
      ]);
      expect(real.exitCode, 0, reason: real.stderr.toString());
      final envelope = _json(real);
      expect(envelope['apiVersion'], veloraApiVersion);
      expect(envelope['type'], 'component.detail');
      final data = envelope['data'] as Map;
      expect(data['import'], "import 'package:velora_ui/velora_ui.dart';");
      final parameters =
          ((data['constructors'] as List).first as Map)['parameters'] as List;
      expect(parameters.map((x) => (x as Map)['name']), contains('onPressed'));
      final answeredBy = (envelope['meta'] as Map)['answeredBy'] as Map;
      expect(answeredBy['cli'], veloraCliVersion);
      expect(answeredBy['project'], isTrue);
      expect((answeredBy['packages'] as Map).keys, contains('velora_ui'));

      final fake = await _cli(_project({'velora_ui': _fakeUi()}), [
        'component',
        'VeloraButton',
        '--detail',
        'brief',
        '--json',
      ]);
      final fakeEnvelope = _json(fake);
      final fakeData = fakeEnvelope['data'] as Map;
      expect(
        (((fakeData['constructors'] as List).first as Map)['parameters']
                as List)
            .map((x) => (x as Map)['name']),
        ['caption'],
      );
      expect(fakeData.containsKey('documentation'), isFalse);
      expect(
        (((fakeEnvelope['meta'] as Map)['answeredBy'] as Map)['packages']
            as Map)['velora_ui'],
        '9.9.9',
      );
    });

    test('errors carry a stable code and exit 64', () async {
      final project = _realProject();
      final unknown = await _cli(project, ['component', 'Nope', '--json']);
      expect(unknown.exitCode, 64);
      expect(_json(unknown)['code'], 'ERR_UNKNOWN_COMPONENT');

      final typo = await _cli(project, ['docs', 'archtecture', '--json']);
      expect(_json(typo)['code'], 'ERR_UNKNOWN_DOCS_TOPIC');
      expect(
        ((_json(typo)['suggestions'] as List).first as Map)['name'],
        'architecture',
      );

      final option = await _cli(project, ['search', 'x', '--nope', '--json']);
      expect(_json(option)['code'], 'ERR_INVALID_ARGUMENT');

      final command = await _cli(project, ['serch', '--json']);
      expect(command.exitCode, 64);
      expect(_json(command)['code'], 'ERR_UNKNOWN_COMMAND');
      expect(
        ((_json(command)['suggestions'] as List).first as Map)['name'],
        'search',
      );

      final outside = Directory.systemTemp.createTempSync('velora_cli_out_');
      addTearDown(() => outside.deleteSync(recursive: true));
      final noProject = await _cli(outside, ['component', '--json']);
      expect(_json(noProject)['code'], 'ERR_PROJECT_REQUIRED');

      final plain = await _cli(project, ['component', 'VeloraDatTable']);
      expect(plain.exitCode, 64);
      expect(plain.stdout, isEmpty);
      expect(plain.stderr, contains('Did you mean: VeloraDataTable'));
    });

    test(
      'docs serves the installed page, or says it is not installed',
      () async {
        final installed = await _cli(_realProject(), [
          'docs',
          'architecture',
          '--json',
        ]);
        final data = _json(installed)['data'] as Map;
        expect(data['installed'], isTrue);
        expect(
          data['content'],
          File(p.join(_repoPackages, '..', 'docs', 'architecture.md'))
              .readAsStringSync(),
        );

        final hosted = await _cli(_project({'velora_ui': _fakeUi()}), [
          'docs',
          'architecture',
        ]);
        expect(hosted.exitCode, 0);
        expect(hosted.stdout, contains('not part of the installed packages'));
        expect(
          hosted.stdout,
          contains('https://md-riaz.github.io/velora-flutter/architecture/'),
        );

        final list = await _cli(Directory.systemTemp, ['docs', '--json']);
        expect(
          ((_json(list)['data'] as Map)['topics'] as List).length,
          veloraDocsTopics.length,
        );
      },
    );

    test('search and manifest work outside a project', () async {
      final outside = Directory.systemTemp.createTempSync('velora_cli_out_');
      addTearDown(() => outside.deleteSync(recursive: true));

      final search = await _cli(outside, ['search', 'offline', '--json']);
      expect(search.exitCode, 0, reason: search.stderr.toString());
      final data = _json(search)['data'] as Map;
      expect(data['componentsSearched'], isFalse);
      expect(data['results'], isNotEmpty);

      final onlyComponents = await _cli(outside, [
        'search',
        'button',
        '--type=component',
        '--json',
      ]);
      expect(_json(onlyComponents)['code'], 'ERR_PROJECT_REQUIRED');

      final manifest = await _cli(outside, ['manifest', '--json']);
      final m = _json(manifest)['data'] as Map;
      expect((m['counts'] as Map)['components'], isNull);
      expect(
        (m['commands'] as List).map((c) => (c as Map)['name']),
        veloraCommands.map((c) => c.name),
      );
      expect(
        (m['errorCodes'] as List).map((e) => (e as Map)['code']),
        VeloraErrorCode.all.map((e) => e.code),
      );
      expect(
        ((_json(manifest)['meta'] as Map)['answeredBy'] as Map)['project'],
        isFalse,
      );
    });

    test('new writes AGENTS.md and a velora_cli dev dependency', () async {
      final dir = Directory.systemTemp.createTempSync('velora_cli_new_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final result = await _cli(dir, ['new', 'shop']);
      expect(result.exitCode, 0, reason: result.stderr.toString());

      final app = p.join(dir.path, 'shop');
      final agents = File(p.join(app, 'AGENTS.md')).readAsStringSync();
      expect(veloraAgentsSectionIsStale(agents), isFalse);
      expect(agents, contains(veloraAgentsStartMarker));

      final pubspec = File(p.join(app, 'pubspec.yaml')).readAsStringSync();
      final dev = pubspec.substring(pubspec.indexOf('dev_dependencies:'));
      final cliPath = RegExp(r'velora_cli:\n    path: (\S+)')
          .firstMatch(dev)!
          .group(1)!;
      expect(
        File(p.join(app, cliPath, 'bin', 'velora_cli.dart')).existsSync(),
        isTrue,
      );
    });

    test('make:agents keeps the rest of AGENTS.md', () async {
      final dir = Directory.systemTemp.createTempSync('velora_cli_agents_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'AGENTS.md'))
        ..writeAsStringSync('# Mine\n');

      expect((await _cli(dir, ['make:agents'])).exitCode, 0);
      final first = file.readAsStringSync();
      expect(first, startsWith('# Mine\n'));
      expect(first, contains(veloraAgentsStartMarker));

      final again = await _cli(dir, ['make:agents']);
      expect(again.stdout, contains('already up to date'));
      expect(file.readAsStringSync(), first);
    });
  });
}
