import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../velora_cli.dart';

/// Local read-only MCP stdio server wrapping Velora's canonical CLI registries.
class VeloraMcpServer {
  VeloraMcpServer({String? projectDirectory})
    : projectDirectory = projectDirectory ?? Directory.current.path;

  final String projectDirectory;

  static const protocolVersion = '2024-11-05';

  static final List<Map<String, Object?>> toolDefinitions = [
    {
      'name': 'search',
      'description': 'Search Velora components, templates, docs topics, packages, and commands.',
      'annotations': {'readOnlyHint': true, 'destructiveHint': false},
      'inputSchema': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'Search query.'},
          'type': {
            'type': 'string',
            'enum': veloraSearchTypes,
            'description': 'Optional entry type filter.',
          },
          'limit': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 50,
            'description': 'Maximum results to return (default 10).',
          },
        },
        'required': ['query'],
      },
    },
    {
      'name': 'component_get',
      'description': 'Inspect a velora_ui export from the project-installed version, or list all components.',
      'annotations': {'readOnlyHint': true, 'destructiveHint': false},
      'inputSchema': {
        'type': 'object',
        'properties': {
          'name': {
            'type': 'string',
            'description': 'Component name; omit to list all components.',
          },
          'detail': {
            'type': 'string',
            'enum': ['brief', 'full'],
            'description': 'Detail level (default brief).',
          },
          'source': {
            'type': 'boolean',
            'description': 'Include the installed source file path.',
          },
        },
      },
    },
    {
      'name': 'template_get',
      'description': 'Inspect a Velora page template specification, or list all templates.',
      'annotations': {'readOnlyHint': true, 'destructiveHint': false},
      'inputSchema': {
        'type': 'object',
        'properties': {
          'id': {
            'type': 'string',
            'description': 'Template ID; omit to list all templates.',
          },
        },
      },
    },
    {
      'name': 'docs_get',
      'description': 'Read a Velora documentation topic from the project-installed checkout, or list topics.',
      'annotations': {'readOnlyHint': true, 'destructiveHint': false},
      'inputSchema': {
        'type': 'object',
        'properties': {
          'topic': {
            'type': 'string',
            'description': 'Topic ID; omit to list available topics.',
          },
        },
      },
    },
    {
      'name': 'package_get',
      'description': 'Inspect an official installable Velora package, or list all catalog packages.',
      'annotations': {'readOnlyHint': true, 'destructiveHint': false},
      'inputSchema': {
        'type': 'object',
        'properties': {
          'name': {
            'type': 'string',
            'description': 'Package name; omit to list all packages.',
          },
        },
      },
    },
    {
      'name': 'doctor_summary',
      'description': 'Run read-only project diagnostics (velora dependency, Velora.boot() wiring, unwired plugins, and AGENTS.md freshness).',
      'annotations': {'readOnlyHint': true, 'destructiveHint': false},
      'inputSchema': {
        'type': 'object',
        'properties': {
          'projectPath': {
            'type': 'string',
            'description': 'Optional project directory override.',
          },
        },
      },
    },
  ];

  /// Serves newline-delimited JSON-RPC 2.0 MCP requests over [input] / [output].
  Future<void> serveStdio({
    Stream<List<int>>? input,
    StreamSink<List<int>>? output,
  }) async {
    final inStream = input ?? stdin;
    final outSink = output ?? stdout;
    final lines = inStream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      Map<String, Object?>? response;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is! Map<String, Object?>) {
          response = _jsonRpcError(null, -32600, 'Invalid Request');
        } else {
          response = await handleMessage(decoded);
        }
      } on FormatException catch (error) {
        response = _jsonRpcError(null, -32700, 'Parse error: ${error.message}');
      }
      if (response != null) {
        outSink.add(utf8.encode('${jsonEncode(response)}\n'));
      }
    }
  }

  /// Handles one decoded JSON-RPC 2.0 request. Returns `null` for notifications.
  Future<Map<String, Object?>?> handleMessage(
    Map<String, Object?> message,
  ) async {
    final id = message['id'];
    final method = message['method'];
    if (method is! String) {
      return id == null
          ? null
          : _jsonRpcError(id, -32600, 'Missing method name.');
    }

    // Notifications (no id) do not receive a JSON-RPC response.
    if (id == null) return null;

    final params = message['params'] is Map<String, Object?>
        ? message['params']! as Map<String, Object?>
        : const <String, Object?>{};

    switch (method) {
      case 'initialize':
        return _jsonRpcResult(id, {
          'protocolVersion': protocolVersion,
          'capabilities': {
            'tools': {'listChanged': false},
          },
          'serverInfo': {'name': veloraCliName, 'version': veloraCliVersion},
        });
      case 'ping':
        return _jsonRpcResult(id, <String, Object?>{});
      case 'tools/list':
        return _jsonRpcResult(id, {'tools': toolDefinitions});
      case 'tools/call':
        final name = params['name'];
        if (name is! String || name.isEmpty) {
          return _jsonRpcError(id, -32602, 'Tool name is required.');
        }
        final args = params['arguments'] is Map<String, Object?>
            ? params['arguments']! as Map<String, Object?>
            : const <String, Object?>{};
        return _jsonRpcResult(id, _callTool(name, args));
      default:
        return _jsonRpcError(id, -32601, 'Method not found: $method');
    }
  }

  Map<String, Object?> _callTool(String name, Map<String, Object?> args) {
    try {
      final payload = switch (name) {
        'search' => _search(args),
        'component_get' => _componentGet(args),
        'template_get' => _templateGet(args),
        'docs_get' => _docsGet(args),
        'package_get' => _packageGet(args),
        'doctor_summary' => _doctorSummary(args),
        _ => throw VeloraCliError(
          VeloraErrorCode.invalidArgument,
          'Unknown tool: $name',
          suggestions: suggestNames(
            name,
            toolDefinitions.map((t) => t['name']! as String),
          ),
        ),
      };
      return {
        'content': [
          {
            'type': 'text',
            'text': const JsonEncoder.withIndent('  ').convert(payload),
          },
        ],
        'structuredContent': payload,
        'isError': false,
      };
    } on VeloraCliError catch (error) {
      final errPayload = veloraErrorEnvelope(error);
      return {
        'content': [
          {
            'type': 'text',
            'text': const JsonEncoder.withIndent('  ').convert(errPayload),
          },
        ],
        'structuredContent': errPayload,
        'isError': true,
      };
    }
  }

  Map<String, Object?> _search(Map<String, Object?> args) {
    final query = args['query'];
    if (query is! String || query.trim().isEmpty) {
      throw const VeloraCliError(
        VeloraErrorCode.invalidArgument,
        'Argument "query" must be a non-empty string.',
      );
    }
    final type = args['type'];
    Set<String>? types;
    if (type != null) {
      if (type is! String || !veloraSearchTypes.contains(type)) {
        throw VeloraCliError(
          VeloraErrorCode.invalidArgument,
          'Invalid search type "$type". Expected one of: '
          '${veloraSearchTypes.join(', ')}.',
        );
      }
      types = {type};
    }
    final rawLimit = args['limit'];
    var limit = 10;
    if (rawLimit != null) {
      if (rawLimit is! int || rawLimit <= 0 || rawLimit > 50) {
        throw const VeloraCliError(
          VeloraErrorCode.invalidArgument,
          'Argument "limit" must be an integer between 1 and 50.',
        );
      }
      limit = rawLimit;
    }
    final project = VeloraProject.find(projectDirectory);
    VeloraUiCatalog? catalog;
    if (project != null && project.packages.containsKey('velora_ui')) {
      catalog = VeloraUiCatalog.load(project);
    }
    final hits = veloraSearch(
      query,
      catalog: catalog,
      types: types,
      limit: limit,
    );
    return veloraEnvelope('search.results', {
      'query': query,
      'results': [for (final h in hits) h.toJson()],
    }, project);
  }

  Map<String, Object?> _componentGet(Map<String, Object?> args) {
    final project = VeloraProject.find(projectDirectory);
    final catalog = VeloraUiCatalog.load(project);
    final name = args['name'];
    if (name == null || (name is String && name.trim().isEmpty)) {
      return veloraEnvelope('component.list', {
        'components': [for (final c in catalog.components) catalog.brief(c)],
      }, project);
    }
    if (name is! String) {
      throw const VeloraCliError(
        VeloraErrorCode.invalidArgument,
        'Argument "name" must be a string.',
      );
    }
    final detail = args['detail'] ?? 'brief';
    if (detail != 'brief' && detail != 'full') {
      throw const VeloraCliError(
        VeloraErrorCode.invalidArgument,
        'Argument "detail" must be "brief" or "full".',
      );
    }
    final includeSource = args['source'] == true;
    final component = catalog.find(name);
    final data = catalog.detail(component, full: detail == 'full');
    return veloraEnvelope('component.detail', {
      ...data,
      if (includeSource) 'sourcePath': catalog.sourcePath(component),
    }, project);
  }

  Map<String, Object?> _templateGet(Map<String, Object?> args) {
    final id = args['id'];
    if (id == null || (id is String && id.trim().isEmpty)) {
      return veloraEnvelope('template.list', {
        'templates': [for (final t in veloraTemplates) t.toJson()],
      }, null);
    }
    if (id is! String) {
      throw const VeloraCliError(
        VeloraErrorCode.invalidArgument,
        'Argument "id" must be a string.',
      );
    }
    final template = veloraTemplates.where((t) => t.id == id).firstOrNull;
    if (template == null) {
      throw VeloraCliError(
        VeloraErrorCode.unknownTemplate,
        'Unknown template: $id',
        suggestions: suggestNames(id, veloraTemplates.map((t) => t.id)),
      );
    }
    return veloraEnvelope('template.detail', template.toJson(), null);
  }

  Map<String, Object?> _docsGet(Map<String, Object?> args) {
    final project = VeloraProject.find(projectDirectory);
    final id = args['topic'];
    if (id == null || (id is String && id.trim().isEmpty)) {
      return veloraEnvelope('docs.list', {
        'topics': [for (final t in veloraDocsTopics) t.toJson()],
      }, project);
    }
    if (id is! String) {
      throw const VeloraCliError(
        VeloraErrorCode.invalidArgument,
        'Argument "topic" must be a string.',
      );
    }
    final topic = veloraDocsTopics.where((t) => t.id == id).firstOrNull;
    if (topic == null) {
      throw VeloraCliError(
        VeloraErrorCode.unknownDocsTopic,
        'No docs topic named $id',
        suggestions: suggestNames(id, veloraDocsTopics.map((t) => t.id)),
      );
    }
    if (project == null) {
      throw const VeloraCliError(
        VeloraErrorCode.projectRequired,
        'Run inside a Flutter project so docs match installed Velora packages.',
      );
    }
    final file = project.docsFile(topic.path);
    final online = Uri.parse(veloraDocsSiteUrl)
        .resolve(
          '${topic.path.substring('docs/'.length, topic.path.length - 3)}/',
        )
        .toString();
    final content = file == null ? null : File(file).readAsStringSync();
    return veloraEnvelope('docs.page', {
      ...topic.toJson(),
      'installed': content != null,
      'file': file,
      'content': content,
      'online': online,
    }, project);
  }

  Map<String, Object?> _packageGet(Map<String, Object?> args) {
    final project = VeloraProject.find(projectDirectory);
    final name = args['name'];
    if (name == null || (name is String && name.trim().isEmpty)) {
      return veloraEnvelope('package.list', {
        'packages': [
          for (final entry in veloraPackageCatalog.entries)
            {
              'name': entry.key,
              'summary': entry.value.summary,
              'pluginExpr': entry.value.pluginExpr,
              'wiresPlugin': entry.value.wiresPlugin,
              'wiring': entry.value.wiring,
              'docs': entry.value.docs,
              if (project != null)
                'installedVersion': project.packages[entry.key]?.version,
            },
        ],
      }, project);
    }
    if (name is! String) {
      throw const VeloraCliError(
        VeloraErrorCode.invalidArgument,
        'Argument "name" must be a string.',
      );
    }
    final pkg = veloraPackageCatalog[name];
    if (pkg == null) {
      throw VeloraCliError(
        VeloraErrorCode.invalidArgument,
        'Unknown Velora package: $name',
        suggestions: suggestNames(name, veloraPackageCatalog.keys),
      );
    }
    return veloraEnvelope('package.detail', {
      'name': pkg.name,
      'summary': pkg.summary,
      'importLine': pkg.importLine,
      'pluginExpr': pkg.pluginExpr,
      'wiresPlugin': pkg.wiresPlugin,
      'wiring': pkg.wiring,
      'docs': pkg.docs,
      'notes': pkg.notes,
      if (project != null)
        'installedVersion': project.packages[pkg.name]?.version,
    }, project);
  }

  Map<String, Object?> _doctorSummary(Map<String, Object?> args) {
    final override = args['projectPath'];
    final targetDir = override is String && override.trim().isNotEmpty
        ? override
        : projectDirectory;
    final pubspecFile = File(p.join(targetDir, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw VeloraCliError(
        VeloraErrorCode.projectRequired,
        'No pubspec.yaml found in $targetDir.',
      );
    }
    final pubspecContent = pubspecFile.readAsStringSync();
    final hasVelora = pubspecDeclaresDependency(pubspecContent, 'velora');

    final mainFile = File(p.join(targetDir, 'lib', 'main.dart'));
    final mainContent = mainFile.existsSync()
        ? mainFile.readAsStringSync()
        : '';
    final callsBoot =
        mainContent.isNotEmpty && mainCallsVeloraBoot(mainContent);

    final unwiredPlugins = <String>[];
    for (final pkg in veloraPackageCatalog.values) {
      if (!pkg.wiresPlugin) continue;
      if (!pubspecDeclaresDependency(pubspecContent, pkg.name)) continue;
      if (mainContent.isNotEmpty &&
          !bootWiresPlugin(mainContent, pkg.pluginExpr!)) {
        unwiredPlugins.add(pkg.name);
      }
    }

    final agentsFile = File(p.join(targetDir, 'AGENTS.md'));
    final agentsContent = agentsFile.existsSync()
        ? agentsFile.readAsStringSync()
        : '';
    final agentsStatus = agentsFile.existsSync()
        ? (veloraAgentsSectionIsStale(agentsContent) ? 'stale' : 'current')
        : 'missing';

    final warnings = <String>[
      if (!hasVelora) 'pubspec.yaml does not declare velora.',
      if (!mainFile.existsSync()) 'lib/main.dart is missing.',
      if (mainFile.existsSync() && !callsBoot)
        'lib/main.dart does not call Velora.boot().',
      for (final pkg in unwiredPlugins)
        '$pkg is declared in pubspec.yaml but not wired into Velora.boot().',
      if (agentsStatus != 'current')
        'AGENTS.md managed Velora section is $agentsStatus.',
    ];

    final project = VeloraProject.find(targetDir);
    return veloraEnvelope('doctor.summary', {
      'projectDirectory': targetDir,
      'healthy': hasVelora && warnings.isEmpty,
      'hasVeloraDependency': hasVelora,
      'hasMainDart': mainFile.existsSync(),
      'callsVeloraBoot': callsBoot,
      'unwiredPlugins': unwiredPlugins,
      'agentsMdStatus': agentsStatus,
      'warnings': warnings,
    }, project);
  }

  Map<String, Object?> _jsonRpcResult(Object id, Map<String, Object?> result) =>
      {'jsonrpc': '2.0', 'id': id, 'result': result};

  Map<String, Object?> _jsonRpcError(Object? id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };
}
