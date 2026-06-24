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
}
