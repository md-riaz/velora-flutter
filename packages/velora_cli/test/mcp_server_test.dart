import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:velora_cli/velora_cli.dart';

String _repoRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File(p.join(dir.path, 'tool', 'check_docs.sh')).existsSync()) {
      return dir.path;
    }
    if (dir.parent.path == dir.path) {
      throw StateError('Repo root not found from ${Directory.current.path}');
    }
    dir = dir.parent;
  }
}

void main() {
  late Directory projectRoot;
  late String projectDir;

  setUpAll(() {
    final repo = _repoRoot();
    projectRoot = Directory.systemTemp.createTempSync('velora_mcp_test_');
    projectDir = projectRoot.path;
    File(p.join(projectDir, 'pubspec.yaml')).writeAsStringSync('''
name: mcp_test_app
dependencies:
  velora: ^0.0.1
  velora_ui: ^0.0.1
''');
    File(p.join(projectDir, 'lib', 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:velora/velora.dart';

Future<void> main() async {
  await Velora.boot(config: const VeloraConfig(appName: 'T', apiBaseUrl: 'http://localhost'));
}
''');
    File(p.join(projectDir, '.dart_tool', 'package_config.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'velora',
              'rootUri': Uri.directory(p.join(repo, 'packages', 'velora'))
                  .toString(),
              'packageUri': 'lib/',
            },
            {
              'name': 'velora_ui',
              'rootUri': Uri.directory(p.join(repo, 'packages', 'velora_ui'))
                  .toString(),
              'packageUri': 'lib/',
            },
          ],
        }),
      );
  });

  tearDownAll(() => projectRoot.deleteSync(recursive: true));

  test('initialize, ping, and tools/list expose 6 read-only tools', () async {
    final server = VeloraMcpServer(projectDirectory: projectDir);

    final init = await server.handleMessage({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {},
    });
    expect(
      (init!['result'] as Map)['protocolVersion'],
      VeloraMcpServer.protocolVersion,
    );

    final notif = await server.handleMessage({
      'jsonrpc': '2.0',
      'method': 'notifications/initialized',
    });
    expect(notif, isNull);

    final ping = await server.handleMessage({
      'jsonrpc': '2.0',
      'id': 2,
      'method': 'ping',
    });
    expect(ping!['result'], isEmpty);

    final list = await server.handleMessage({
      'jsonrpc': '2.0',
      'id': 3,
      'method': 'tools/list',
    });
    final tools = ((list!['result'] as Map)['tools'] as List).cast<Map>();
    expect(tools.map((t) => t['name']), [
      'search',
      'component_get',
      'template_get',
      'docs_get',
      'package_get',
      'doctor_summary',
    ]);
    for (final tool in tools) {
      expect((tool['annotations'] as Map)['readOnlyHint'], isTrue);
      expect((tool['annotations'] as Map)['destructiveHint'], isFalse);
    }
  });

  test('all 6 MCP tools wrap canonical registries and handle errors', () async {
    final server = VeloraMcpServer(projectDirectory: projectDir);

    Future<Map<String, Object?>> call(
      int id,
      String name, [
      Map<String, Object?> args = const {},
    ]) async {
      final resp = await server.handleMessage({
        'jsonrpc': '2.0',
        'id': id,
        'method': 'tools/call',
        'params': {'name': name, 'arguments': args},
      });
      return resp!['result']! as Map<String, Object?>;
    }

    final searchRes = await call(1, 'search', {
      'query': 'crud-list',
      'type': 'template',
    });
    expect(searchRes['isError'], isFalse);
    final searchData =
        (searchRes['structuredContent'] as Map)['data'] as Map<String, Object?>;
    expect((searchData['results'] as List).first['name'], 'crud-list');

    final compRes = await call(2, 'component_get', {
      'name': 'AdaptiveShell',
      'source': true,
    });
    expect(compRes['isError'], isFalse);
    final compData =
        (compRes['structuredContent'] as Map)['data'] as Map<String, Object?>;
    expect(compData['name'], 'AdaptiveShell');
    expect(compData['sourcePath'], isA<String>());

    final tplRes = await call(3, 'template_get', {'id': 'wizard'});
    expect(tplRes['isError'], isFalse);
    expect(
      ((tplRes['structuredContent'] as Map)['data'] as Map)['id'],
      'wizard',
    );

    final docsRes = await call(4, 'docs_get', {'topic': 'architecture'});
    expect(docsRes['isError'], isFalse);
    expect(
      ((docsRes['structuredContent'] as Map)['data'] as Map)['installed'],
      isTrue,
    );

    final pkgRes = await call(5, 'package_get', {'name': 'velora_db'});
    expect(pkgRes['isError'], isFalse);
    expect(
      ((pkgRes['structuredContent'] as Map)['data'] as Map)['wiresPlugin'],
      isTrue,
    );

    final doctorRes = await call(6, 'doctor_summary');
    expect(doctorRes['isError'], isFalse);
    final docData =
        (doctorRes['structuredContent'] as Map)['data'] as Map<String, Object?>;
    expect(docData['hasVeloraDependency'], isTrue);
    expect(docData['callsVeloraBoot'], isTrue);

    final unknownTool = await call(7, 'write_files');
    expect(unknownTool['isError'], isTrue);
    expect(
      (unknownTool['structuredContent'] as Map)['code'],
      'ERR_INVALID_ARGUMENT',
    );
  });

  test('serveStdio processes newline-delimited JSON-RPC messages', () async {
    final server = VeloraMcpServer(projectDirectory: projectDir);
    final input = Stream<List<int>>.fromIterable([
      utf8.encode(
        '{"jsonrpc":"2.0","id":10,"method":"tools/call",'
        '"params":{"name":"template_get","arguments":{}}}\n',
      ),
    ]);
    final outputLines = <String>[];
    final controller = StreamController<List<int>>();
    final sub = controller.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(outputLines.add);

    await server.serveStdio(input: input, output: controller.sink);
    await controller.close();
    await sub.cancel();

    expect(outputLines, hasLength(1));
    final decoded = jsonDecode(outputLines.single) as Map<String, dynamic>;
    expect(decoded['id'], 10);
    final result = decoded['result'] as Map<String, dynamic>;
    expect(result['isError'], isFalse);
  });

  test('CLI serves requests over stdio before stdin closes', () async {
    final process = await Process.start(Platform.resolvedExecutable, [
      'run',
      'bin/velora_cli.dart',
      'mcp',
      '--project',
      projectDir,
    ]);
    try {
      final response = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;
      process.stdin.writeln('{"jsonrpc":"2.0","id":1,"method":"ping"}');
      await process.stdin.flush();
      final decoded = jsonDecode(
        await response.timeout(const Duration(seconds: 20)),
      ) as Map;
      expect(decoded['id'], 1);
      expect(decoded['result'], isEmpty);
    } finally {
      await process.stdin.close();
      await process.exitCode.timeout(const Duration(seconds: 20));
    }
  });
}
