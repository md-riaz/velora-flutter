import 'dart:io';

import 'package:velora_cli/velora_cli.dart';
import 'package:test/test.dart';

void main() {
  test('exposes CLI metadata', () {
    expect(veloraCliName, 'velora_cli');
    expect(veloraCliVersion, '0.0.1');
  });

  test('notification commands write expected files', () async {
    final temp = Directory.systemTemp.createTempSync(
      'velora_cli_notifications_',
    );
    addTearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    final packageRoot = Directory.current.path;
    Future<ProcessResult> runCli(List<String> args) {
      return Process.run(Platform.resolvedExecutable, <String>[
        '$packageRoot/bin/velora_cli.dart',
        ...args,
      ], workingDirectory: Directory.current.path);
    }

    final app = Directory('${temp.path}/app')..createSync();
    final original = Directory.current;
    try {
      Directory.current = app;
      final make = await runCli(<String>['make:notifications']);
      expect(make.exitCode, 0, reason: make.stderr.toString());

      final fcm = await runCli(<String>['install:push', '--fcm']);
      expect(fcm.exitCode, 0, reason: fcm.stderr.toString());

      final local = await runCli(<String>['install:push', '--local']);
      expect(local.exitCode, 0, reason: local.stderr.toString());
    } finally {
      Directory.current = original;
    }

    expect(
      File(
        '${app.path}/lib/app/modules/notifications/application/notification_service.dart',
      ).existsSync(),
      isTrue,
    );
    expect(File('${app.path}/.ai/notifications.md').existsSync(), isTrue);
    expect(
      File('${app.path}/web/firebase-messaging-sw.js').existsSync(),
      isTrue,
    );
    expect(File('${app.path}/docs/reminders/android.md').existsSync(), isTrue);
    expect(File('${app.path}/docs/reminders/ios.md').existsSync(), isTrue);
    expect(File('${app.path}/docs/reminders/web.md').existsSync(), isTrue);
    expect(File('${app.path}/docs/reminders/laravel.md').existsSync(), isTrue);
  });

  group('addDependencyToPubspec', () {
    test('inserts the dependency as the first entry under dependencies:', () {
      const pubspec = '''name: demo
dependencies:
  flutter:
    sdk: flutter
''';
      final updated = addDependencyToPubspec(
        pubspec,
        'velora_offline',
        '^0.0.1',
      );
      expect(updated, contains('dependencies:\n  velora_offline: ^0.0.1\n'));
      final depsIndex = updated.indexOf('dependencies:');
      final veloraIndex = updated.indexOf('velora_offline:');
      final flutterIndex = updated.indexOf('flutter:');
      expect(veloraIndex, greaterThan(depsIndex));
      expect(veloraIndex, lessThan(flutterIndex));
    });

    test('is idempotent when run twice', () {
      const pubspec = '''name: demo
dependencies:
  flutter:
    sdk: flutter
''';
      final once = addDependencyToPubspec(pubspec, 'velora_offline', '^0.0.1');
      final twice = addDependencyToPubspec(once, 'velora_offline', '^0.0.1');
      expect(twice, once);
      expect('velora_offline:'.allMatches(twice).length, 1);
    });

    test('leaves an existing dependency unchanged', () {
      const pubspec = '''name: demo
dependencies:
  velora_offline: ^9.9.9
  flutter:
    sdk: flutter
''';
      final updated = addDependencyToPubspec(
        pubspec,
        'velora_offline',
        '^0.0.1',
      );
      expect(updated, pubspec);
    });

    test('appends a dependencies block when none exists', () {
      const pubspec = 'name: demo\n';
      final updated = addDependencyToPubspec(
        pubspec,
        'velora_offline',
        '^0.0.1',
      );
      expect(updated, contains('dependencies:\n  velora_offline: ^0.0.1'));
    });

    test(
      'still adds to dependencies: when the name only exists under '
      'dev_dependencies:',
      () {
        const pubspec = '''name: demo
dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  velora_offline: ^0.0.1
  flutter_test:
    sdk: flutter
''';
        final updated = addDependencyToPubspec(
          pubspec,
          'velora_offline',
          '^0.0.1',
        );
        // Added to dependencies: (not skipped just because it's present
        // under dev_dependencies:), so it now appears twice.
        expect('velora_offline:'.allMatches(updated).length, 2);
        final depsIndex = updated.indexOf('dependencies:');
        final devDepsIndex = updated.indexOf('dev_dependencies:');
        final firstVeloraIndex = updated.indexOf('velora_offline:');
        expect(firstVeloraIndex, greaterThan(depsIndex));
        expect(firstVeloraIndex, lessThan(devDepsIndex));
      },
    );
  });

  group('wirePluginIntoBoot', () {
    const importLine = "import 'package:velora_offline/velora_offline.dart';";
    const pluginExpr = 'VeloraOfflinePlugin()';

    test('adds import and a plugins arg when boot() has none', () {
      const main = '''import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

Future<void> main() async {
  await Velora.boot(config: config);
}
''';
      final result = wirePluginIntoBoot(
        main,
        importLine: importLine,
        pluginExpr: pluginExpr,
      );
      expect(result.wired, isTrue);
      expect(result.content, contains(importLine));
      expect(
        result.content,
        contains('Velora.boot(config: config, plugins: [VeloraOfflinePlugin()])'),
      );
      expect(result.content, contains('config: config'));
      expect(result.content, isNot(contains('  plugins:')));
    });

    test(
      'appends plugins arg with no leading separator for an empty boot() call',
      () {
        const main = '''import 'package:velora/velora.dart';

Future<void> main() async {
  await Velora.boot();
}
''';
        final result = wirePluginIntoBoot(
          main,
          importLine: importLine,
          pluginExpr: pluginExpr,
        );
        expect(result.wired, isTrue);
        expect(
          result.content,
          contains('Velora.boot(plugins: [VeloraOfflinePlugin()])'),
        );
      },
    );

    test(
      'does not duplicate the import when it already exists with double '
      'quotes',
      () {
        const main = '''import "package:velora/velora.dart";
import "package:velora_offline/velora_offline.dart";

Future<void> main() async {
  await Velora.boot(config: config);
}
''';
        final result = wirePluginIntoBoot(
          main,
          importLine: importLine,
          pluginExpr: pluginExpr,
        );
        expect(result.wired, isTrue);
        expect(
          'package:velora_offline/velora_offline.dart'.allMatches(result.content).length,
          1,
        );
      },
    );

    test('appends into an existing plugins list', () {
      const main = '''import 'package:velora/velora.dart';

Future<void> main() async {
  await Velora.boot(
    config: config,
    plugins: [VeloraFcm()],
  );
}
''';
      final result = wirePluginIntoBoot(
        main,
        importLine: importLine,
        pluginExpr: pluginExpr,
      );
      expect(result.wired, isTrue);
      expect(
        result.content,
        contains('plugins: [VeloraOfflinePlugin(), VeloraFcm()]'),
      );
    });

    test('is idempotent when run twice', () {
      const main = '''import 'package:velora/velora.dart';

Future<void> main() async {
  await Velora.boot(config: config);
}
''';
      final once = wirePluginIntoBoot(
        main,
        importLine: importLine,
        pluginExpr: pluginExpr,
      );
      final twice = wirePluginIntoBoot(
        once.content,
        importLine: importLine,
        pluginExpr: pluginExpr,
      );
      expect(twice.content, once.content);
      expect(pluginExpr.allMatches(twice.content).length, 1);
      expect(importLine.allMatches(twice.content).length, 1);
    });

    test('returns wired: false when there is no Velora.boot(', () {
      const main = '''void main() {
  print('no velora here');
}
''';
      final result = wirePluginIntoBoot(
        main,
        importLine: importLine,
        pluginExpr: pluginExpr,
      );
      expect(result.wired, isFalse);
    });
  });

  test('catalog contains velora_offline', () {
    expect(veloraPackageCatalog.containsKey('velora_offline'), isTrue);
    final package = veloraPackageCatalog['velora_offline']!;
    expect(package.name, 'velora_offline');
    expect(package.pluginExpr, 'VeloraOfflinePlugin()');
  });

  test('install command wires a package into a generated app', () async {
    final temp = Directory.systemTemp.createTempSync('velora_cli_install_');
    addTearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    final packageRoot = Directory.current.path;
    Future<ProcessResult> runCli(List<String> args) {
      return Process.run(Platform.resolvedExecutable, <String>[
        '$packageRoot/bin/velora_cli.dart',
        ...args,
      ], workingDirectory: Directory.current.path);
    }

    final app = Directory('${temp.path}/app')..createSync();
    File('${app.path}/pubspec.yaml').writeAsStringSync('''name: demo
dependencies:
  flutter:
    sdk: flutter
''');
    Directory('${app.path}/lib').createSync();
    File('${app.path}/lib/main.dart').writeAsStringSync('''
Future<void> main() async {
  await Velora.boot(config: config);
}
''');

    final original = Directory.current;
    try {
      Directory.current = app;
      final install = await runCli(<String>[
        'install',
        'velora_offline',
        '--no-pub-get',
      ]);
      expect(install.exitCode, 0, reason: install.stderr.toString());
    } finally {
      Directory.current = original;
    }

    final pubspecContent = File('${app.path}/pubspec.yaml').readAsStringSync();
    expect(pubspecContent, contains('velora_offline:'));

    final mainContent = File('${app.path}/lib/main.dart').readAsStringSync();
    expect(mainContent, contains('VeloraOfflinePlugin()'));
    expect(
      mainContent,
      contains("import 'package:velora_offline/velora_offline.dart';"),
    );
  });
}
