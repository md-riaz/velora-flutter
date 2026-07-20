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
      'leaves an existing 4-space-indented dependency unchanged '
      '(idempotent regardless of indentation width)',
      () {
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
        expect('velora_offline:'.allMatches(updated).length, 1);
      },
    );

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

    test(
      'wires the real Velora.boot( call even when a doc comment and a '
      'string literal mention Velora.boot( first, leaving them untouched',
      () {
        const commentLine = '/// See Velora.boot(...) for setup.';
        const stringLine = "const note = 'call Velora.boot() first';";
        const main =
            "import 'package:velora/velora.dart';\n"
            '\n'
            '$commentLine\n'
            '$stringLine\n'
            '\n'
            'Future<void> main() async {\n'
            '  await Velora.boot(config: config);\n'
            '}\n';
        final result = wirePluginIntoBoot(
          main,
          importLine: importLine,
          pluginExpr: pluginExpr,
        );
        expect(result.wired, isTrue);
        // The comment and string lines are byte-for-byte preserved.
        expect(result.content, contains(commentLine));
        expect(result.content, contains(stringLine));
        // The plugin was wired into the real call, not the fake mentions.
        expect(
          result.content,
          contains(
            'Velora.boot(config: config, plugins: [VeloraOfflinePlugin()])',
          ),
        );
        // Only the real call gained a plugins: argument.
        expect('plugins:'.allMatches(result.content).length, 1);
      },
    );
  });

  group('wirePluginIntoBoot: pre-existing non-literal plugins: argument', () {
    const importLine = "import 'package:velora_offline/velora_offline.dart';";
    const pluginExpr = 'VeloraOfflinePlugin()';

    test(
      'does not insert a second plugins: when the argument is an identifier',
      () {
        const main = '''import 'package:velora/velora.dart';

Future<void> main() async {
  await Velora.boot(plugins: appPlugins);
}
''';
        final result = wirePluginIntoBoot(
          main,
          importLine: importLine,
          pluginExpr: pluginExpr,
        );
        expect(result.wired, isFalse);
        expect('plugins:'.allMatches(result.content).length, 1);
        expect(result.content, contains('plugins: appPlugins'));
      },
    );

    test(
      'does not insert a second plugins: when the argument is a const list '
      'literal, and leaves it unchanged',
      () {
        const main = '''import 'package:velora/velora.dart';

Future<void> main() async {
  await Velora.boot(plugins: const [Foo()]);
}
''';
        final result = wirePluginIntoBoot(
          main,
          importLine: importLine,
          pluginExpr: pluginExpr,
        );
        expect(result.wired, isFalse);
        expect('plugins:'.allMatches(result.content).length, 1);
        expect(result.content, contains('plugins: const [Foo()]'));
      },
    );

    test('still merges into a plain inline plugins: [...] literal', () {
      const main = '''import 'package:velora/velora.dart';

Future<void> main() async {
  await Velora.boot(plugins: [Foo()]);
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
        contains('plugins: [VeloraOfflinePlugin(), Foo()]'),
      );
      expect('plugins:'.allMatches(result.content).length, 1);
    });
  });

  group('mainCallsVeloraBoot', () {
    test('is false when Velora.boot( only appears in a // comment', () {
      const main = '''
// TODO: call Velora.boot( here once config is ready.
void main() {}
''';
      expect(mainCallsVeloraBoot(main), isFalse);
    });

    test('is false when Velora.boot( only appears in a string literal', () {
      const main = '''
void main() {
  print('remember to call Velora.boot(...)');
}
''';
      expect(mainCallsVeloraBoot(main), isFalse);
    });

    test('is true for a real Velora.boot( call', () {
      const main = '''
import 'package:velora/velora.dart';

Future<void> main() async {
  await Velora.boot(config: config);
}
''';
      expect(mainCallsVeloraBoot(main), isTrue);
    });

    test('is true for Velora.boot ( with a space before the paren', () {
      const main = '''
import 'package:velora/velora.dart';

Future<void> main() async {
  await Velora.boot (config: config);
}
''';
      expect(mainCallsVeloraBoot(main), isTrue);
    });
  });

  group('bootWiresPlugin', () {
    const pluginExpr = 'VeloraOfflinePlugin()';

    test(
      'is false when the plugin expr only appears in a comment, not the '
      'plugins: list',
      () {
        const main = '''
import 'package:velora/velora.dart';

// VeloraOfflinePlugin() still needs to be added below.
Future<void> main() async {
  await Velora.boot(config: config);
}
''';
        expect(bootWiresPlugin(main, pluginExpr), isFalse);
      },
    );

    test(
      'is false when the plugin expr only appears in a string literal',
      () {
        const main = '''
import 'package:velora/velora.dart';

const note = 'VeloraOfflinePlugin() still needs to be added below.';

Future<void> main() async {
  await Velora.boot(config: config);
}
''';
        expect(bootWiresPlugin(main, pluginExpr), isFalse);
      },
    );

    test(
      'is false when the plugin expr appears elsewhere in the file but not '
      'inside the boot plugins: list',
      () {
        const main = '''
import 'package:velora/velora.dart';

final unrelated = VeloraOfflinePlugin();

Future<void> main() async {
  await Velora.boot(config: config);
}
''';
        expect(bootWiresPlugin(main, pluginExpr), isFalse);
      },
    );

    test('is true when the plugin expr is actually in the plugins: list', () {
      const main = '''
import 'package:velora/velora.dart';

Future<void> main() async {
  await Velora.boot(
    config: config,
    plugins: [VeloraOfflinePlugin()],
  );
}
''';
      expect(bootWiresPlugin(main, pluginExpr), isTrue);
    });
  });

  test('catalog contains velora_offline', () {
    expect(veloraPackageCatalog.containsKey('velora_offline'), isTrue);
    final package = veloraPackageCatalog['velora_offline']!;
    expect(package.name, 'velora_offline');
    expect(package.pluginExpr, 'VeloraOfflinePlugin()');
  });

  test('catalog contains velora_db', () {
    expect(veloraPackageCatalog.containsKey('velora_db'), isTrue);
    final package = veloraPackageCatalog['velora_db']!;
    expect(package.name, 'velora_db');
    expect(package.pluginExpr, 'VeloraDbPlugin()');
    expect(
      package.importLine,
      "import 'package:velora_db/velora_db.dart';",
    );
  });

  test('catalog contains velora_env', () {
    expect(veloraPackageCatalog.containsKey('velora_env'), isTrue);
    final package = veloraPackageCatalog['velora_env']!;
    expect(package.name, 'velora_env');
    expect(package.pluginExpr, 'VeloraEnvPlugin()');
    expect(
      package.importLine,
      "import 'package:velora_env/velora_env.dart';",
    );
    expect(package.notes, isNotEmpty);
  });

  test(
    'velora_offline, velora_db, and velora_env wire a plugin '
    '(wiresPlugin == true)',
    () {
      for (final name in ['velora_offline', 'velora_db', 'velora_env']) {
        final package = veloraPackageCatalog[name]!;
        expect(package.wiresPlugin, isTrue, reason: name);
        expect(package.importLine, isNotNull, reason: name);
        expect(package.pluginExpr, isNotNull, reason: name);
      }
    },
  );

  test(
    'catalog contains velora_fcm and velora_local_notifications as '
    'dependency-only entries (wiresPlugin == false)',
    () {
      for (final name in ['velora_fcm', 'velora_local_notifications']) {
        expect(veloraPackageCatalog.containsKey(name), isTrue, reason: name);
        final package = veloraPackageCatalog[name]!;
        expect(package.name, name);
        expect(package.constraint, '^0.0.1');
        expect(package.wiresPlugin, isFalse, reason: name);
        expect(package.importLine, isNull, reason: name);
        expect(package.pluginExpr, isNull, reason: name);
        expect(package.notes, isNotEmpty, reason: name);
      }
    },
  );

  test('velora_fcm notes reference the real adapter and boot argument', () {
    final notes = veloraPackageCatalog['velora_fcm']!.notes.join('\n');
    expect(notes, contains('VeloraFcmAdapter()'));
    expect(notes, contains('pushAdapter:'));
    expect(notes, contains('Firebase.initializeApp'));
    expect(notes, contains('flutterfire configure'));
  });

  test(
    'velora_local_notifications notes reference the real adapter and boot '
    'argument',
    () {
      final notes = veloraPackageCatalog['velora_local_notifications']!.notes
          .join('\n');
      expect(notes, contains('VeloraLocalNotificationsAdapter()'));
      expect(notes, contains('localAdapter:'));
    },
  );

  test(
    'install velora_fcm --no-pub-get adds the dependency without touching '
    'lib/main.dart, and prints the setup notes',
    () async {
      final temp = Directory.systemTemp.createTempSync(
        'velora_cli_install_fcm_',
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
      File('${app.path}/pubspec.yaml').writeAsStringSync('''name: demo
dependencies:
  flutter:
    sdk: flutter
''');
      Directory('${app.path}/lib').createSync();
      const originalMain = '''
Future<void> main() async {
  await Velora.boot(config: config);
}
''';
      File('${app.path}/lib/main.dart').writeAsStringSync(originalMain);

      final original = Directory.current;
      ProcessResult install;
      try {
        Directory.current = app;
        install = await runCli(<String>[
          'install',
          'velora_fcm',
          '--no-pub-get',
        ]);
        expect(install.exitCode, 0, reason: install.stderr.toString());
      } finally {
        Directory.current = original;
      }

      final pubspecContent = File(
        '${app.path}/pubspec.yaml',
      ).readAsStringSync();
      expect(pubspecContent, contains('velora_fcm: ^0.0.1'));

      final mainContent = File('${app.path}/lib/main.dart').readAsStringSync();
      expect(mainContent, originalMain, reason: 'main.dart must be untouched');

      final stdoutText = install.stdout.toString();
      expect(stdoutText, contains('Added velora_fcm: ^0.0.1 to pubspec.yaml'));
      expect(stdoutText, contains('pushAdapter: VeloraFcmAdapter()'));
      expect(stdoutText, contains('Firebase.initializeApp'));
      expect(stdoutText, isNot(contains('Wired')));
    },
  );

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

  test(
    'install velora_env --no-pub-get adds the dependency, wires '
    'VeloraEnvPlugin() into Velora.boot(), and prints the setup notes',
    () async {
      final temp = Directory.systemTemp.createTempSync(
        'velora_cli_install_env_',
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
      ProcessResult install;
      try {
        Directory.current = app;
        install = await runCli(<String>[
          'install',
          'velora_env',
          '--no-pub-get',
        ]);
        expect(install.exitCode, 0, reason: install.stderr.toString());
      } finally {
        Directory.current = original;
      }

      final pubspecContent = File(
        '${app.path}/pubspec.yaml',
      ).readAsStringSync();
      expect(pubspecContent, contains('velora_env: ^0.0.1'));

      final mainContent = File('${app.path}/lib/main.dart').readAsStringSync();
      expect(mainContent, contains('VeloraEnvPlugin()'));
      expect(
        mainContent,
        contains("import 'package:velora_env/velora_env.dart';"),
      );
      expect(mainContent, contains('plugins: [VeloraEnvPlugin()]'));

      final stdoutText = install.stdout.toString();
      expect(stdoutText, contains('Added velora_env: ^0.0.1 to pubspec.yaml'));
      expect(stdoutText, contains('Wired VeloraEnvPlugin() into Velora.boot()'));
      expect(stdoutText, contains('VeloraEnv.load()'));
      expect(stdoutText, contains('VELORA_ENV'));
    },
  );

  test(
    'install --no-wire adds the dependency but leaves main.dart untouched '
    'and does not print the false wiring claim',
    () async {
      final temp = Directory.systemTemp.createTempSync(
        'velora_cli_install_no_wire_',
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
      File('${app.path}/pubspec.yaml').writeAsStringSync('''name: demo
dependencies:
  flutter:
    sdk: flutter
''');
      Directory('${app.path}/lib').createSync();
      const originalMain = '''
Future<void> main() async {
  await Velora.boot(config: config);
}
''';
      File('${app.path}/lib/main.dart').writeAsStringSync(originalMain);

      final original = Directory.current;
      ProcessResult install;
      try {
        Directory.current = app;
        install = await runCli(<String>[
          'install',
          'velora_offline',
          '--no-pub-get',
          '--no-wire',
        ]);
        expect(install.exitCode, 0, reason: install.stderr.toString());
      } finally {
        Directory.current = original;
      }

      final pubspecContent = File(
        '${app.path}/pubspec.yaml',
      ).readAsStringSync();
      expect(pubspecContent, contains('velora_offline:'));

      final mainContent = File('${app.path}/lib/main.dart').readAsStringSync();
      expect(mainContent, originalMain);

      final stdoutText = install.stdout.toString();
      expect(
        stdoutText,
        isNot(
          contains(
            'Added velora_offline and wired VeloraOfflinePlugin() into '
            'Velora.boot().',
          ),
        ),
      );
      expect(stdoutText, contains('--no-wire was passed'));
      expect(stdoutText, contains('plugins: [VeloraOfflinePlugin()]'));
    },
  );

  test(
    'install with an unknown package name fails loudly without touching '
    'pubspec.yaml or main.dart',
    () async {
      final temp = Directory.systemTemp.createTempSync(
        'velora_cli_install_unknown_',
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
      const originalPubspec = '''name: demo
dependencies:
  flutter:
    sdk: flutter
''';
      File('${app.path}/pubspec.yaml').writeAsStringSync(originalPubspec);
      Directory('${app.path}/lib').createSync();
      const originalMain = '''
Future<void> main() async {
  await Velora.boot(config: config);
}
''';
      File('${app.path}/lib/main.dart').writeAsStringSync(originalMain);

      final original = Directory.current;
      ProcessResult install;
      try {
        Directory.current = app;
        install = await runCli(<String>[
          'install',
          'velora_nope',
          '--no-pub-get',
        ]);
      } finally {
        Directory.current = original;
      }

      expect(install.exitCode, isNot(0));
      final combinedOutput =
          install.stdout.toString() + install.stderr.toString();
      expect(combinedOutput, contains("Unknown package 'velora_nope'"));
      expect(combinedOutput, contains('velora_offline'));

      expect(
        File('${app.path}/pubspec.yaml').readAsStringSync(),
        originalPubspec,
      );
      expect(
        File('${app.path}/lib/main.dart').readAsStringSync(),
        originalMain,
      );
    },
  );

  group('doctor', () {
    Future<ProcessResult> runDoctor(String workingDirectory) {
      final packageRoot = Directory.current.path;
      return Process.run(Platform.resolvedExecutable, <String>[
        '$packageRoot/bin/velora_cli.dart',
        'doctor',
      ], workingDirectory: workingDirectory);
    }

    test('passes in a valid Velora project and reports the passing checks', () async {
      final temp = Directory.systemTemp.createTempSync('velora_cli_doctor_ok_');
      addTearDown(() {
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      });

      final app = Directory('${temp.path}/app')..createSync();
      File('${app.path}/pubspec.yaml').writeAsStringSync('''name: demo
dependencies:
  flutter:
    sdk: flutter
  velora: ^0.0.1
''');
      Directory('${app.path}/lib').createSync();
      File('${app.path}/lib/main.dart').writeAsStringSync('''
Future<void> main() async {
  await Velora.boot(config: config);
}
''');

      final result = await runDoctor(app.path);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final output = result.stdout.toString();
      expect(output, contains('pubspec.yaml declares a `velora` dependency'));
      expect(output, contains('lib/main.dart calls Velora.boot()'));
      expect(output, contains('Dart:'));
    });

    test(
      'fails loudly when there is no pubspec.yaml or velora is not a dependency',
      () async {
        final temp = Directory.systemTemp.createTempSync(
          'velora_cli_doctor_no_pubspec_',
        );
        addTearDown(() {
          if (temp.existsSync()) temp.deleteSync(recursive: true);
        });
        final noPubspecDir = Directory('${temp.path}/no_pubspec')
          ..createSync();

        final noPubspecResult = await runDoctor(noPubspecDir.path);
        // `_fail` always sets `exitCode = 64` — assert the exact contract,
        // not just "some failure code".
        expect(noPubspecResult.exitCode, 64);
        expect(
          noPubspecResult.stdout.toString() +
              noPubspecResult.stderr.toString(),
          contains('No pubspec.yaml'),
        );

        final notVeloraDir = Directory('${temp.path}/not_velora')
          ..createSync();
        File(
          '${notVeloraDir.path}/pubspec.yaml',
        ).writeAsStringSync('''name: demo
dependencies:
  flutter:
    sdk: flutter
''');

        final notVeloraResult = await runDoctor(notVeloraDir.path);
        expect(notVeloraResult.exitCode, 64);
        expect(
          notVeloraResult.stdout.toString() +
              notVeloraResult.stderr.toString(),
          contains('Not a Velora project'),
        );
      },
    );

    test(
      'warns when a declared plugin package is not wired into Velora.boot()',
      () async {
        final temp = Directory.systemTemp.createTempSync(
          'velora_cli_doctor_unwired_',
        );
        addTearDown(() {
          if (temp.existsSync()) temp.deleteSync(recursive: true);
        });

        final app = Directory('${temp.path}/app')..createSync();
        File('${app.path}/pubspec.yaml').writeAsStringSync('''name: demo
dependencies:
  flutter:
    sdk: flutter
  velora: ^0.0.1
  velora_offline: ^0.0.1
''');
        Directory('${app.path}/lib').createSync();
        File('${app.path}/lib/main.dart').writeAsStringSync('''
Future<void> main() async {
  await Velora.boot(config: config);
}
''');

        final result = await runDoctor(app.path);
        expect(result.exitCode, 0, reason: result.stderr.toString());
        final output = result.stdout.toString();
        expect(output, contains('velora_offline'));
        expect(output, contains('VeloraOfflinePlugin()'));
        expect(output, contains('not wired'));
      },
    );

    test(
      'still warns declared-but-not-wired when the plugin expr only '
      'appears in a comment in main.dart',
      () async {
        final temp = Directory.systemTemp.createTempSync(
          'velora_cli_doctor_commented_plugin_',
        );
        addTearDown(() {
          if (temp.existsSync()) temp.deleteSync(recursive: true);
        });

        final app = Directory('${temp.path}/app')..createSync();
        File('${app.path}/pubspec.yaml').writeAsStringSync('''name: demo
dependencies:
  flutter:
    sdk: flutter
  velora: ^0.0.1
  velora_offline: ^0.0.1
''');
        Directory('${app.path}/lib').createSync();
        File('${app.path}/lib/main.dart').writeAsStringSync('''
// TODO: wire VeloraOfflinePlugin() into Velora.boot() below.
Future<void> main() async {
  await Velora.boot(config: config);
}
''');

        final result = await runDoctor(app.path);
        expect(result.exitCode, 0, reason: result.stderr.toString());
        final output = result.stdout.toString();
        expect(output, contains('velora_offline'));
        expect(output, contains('not wired'));
      },
    );

    test(
      'recognizes a Velora project when dependencies: has a trailing '
      'inline comment',
      () async {
        final temp = Directory.systemTemp.createTempSync(
          'velora_cli_doctor_dep_comment_',
        );
        addTearDown(() {
          if (temp.existsSync()) temp.deleteSync(recursive: true);
        });

        final app = Directory('${temp.path}/app')..createSync();
        File('${app.path}/pubspec.yaml').writeAsStringSync('''name: demo
dependencies: # runtime deps
  flutter:
    sdk: flutter
  velora: ^0.0.1
''');
        Directory('${app.path}/lib').createSync();
        File('${app.path}/lib/main.dart').writeAsStringSync('''
Future<void> main() async {
  await Velora.boot(config: config);
}
''');

        final result = await runDoctor(app.path);
        expect(result.exitCode, 0, reason: result.stderr.toString());
        expect(
          result.stdout.toString(),
          contains('pubspec.yaml declares a `velora` dependency'),
        );
      },
    );
  });

  test(
    'main() reports a clean message (not a raw stack trace) when a command '
    'throws an unexpected, non-_CliExit exception',
    () async {
      // `velora new <name>` calls `Directory(name).createSync(recursive:
      // true)`. If a plain *file* already exists at that exact path, the OS
      // refuses to create a directory there and Dart surfaces a
      // FileSystemException — a real, uncontrived exception that isn't
      // routed through `_fail`/`_CliExit`, so it should land in main()'s
      // `catch (error)` branch.
      final temp = Directory.systemTemp.createTempSync(
        'velora_cli_unexpected_error_',
      );
      addTearDown(() {
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      });

      File('${temp.path}/app').writeAsStringSync('not a directory');

      final packageRoot = Directory.current.path;
      final result = await Process.run(Platform.resolvedExecutable, <String>[
        '$packageRoot/bin/velora_cli.dart',
        'new',
        'app',
      ], workingDirectory: temp.path);

      final combined = result.stdout.toString() + result.stderr.toString();
      expect(result.exitCode, 1);
      expect(combined, contains('An unexpected error occurred'));
      // No raw Dart stack trace should leak to the user.
      expect(combined, isNot(contains('Unhandled exception')));
      expect(combined, isNot(contains('#0 ')));
    },
  );
}
