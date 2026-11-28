import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'lib/src/ui/ does not import platform or database packages directly',
    () {
      final uiDir = Directory('lib/src/ui');
      expect(uiDir.existsSync(), isTrue);

      final forbidden = [
        'package:velora_desktop/',
        'package:flutter_local_notifications/',
        'package:drift/',
      ];

      for (final entity in uiDir.listSync(recursive: true).whereType<File>()) {
        if (!entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        for (final pattern in forbidden) {
          expect(
            content.contains(pattern),
            isFalse,
            reason: '${entity.path} must not import $pattern',
          );
        }
      }
    },
  );

  test('lib/src/contracts/ does not import velora or UI files', () {
    final contractsDir = Directory('lib/src/contracts');
    expect(contractsDir.existsSync(), isTrue);

    final forbidden = [
      'package:velora/velora.dart',
      'package:velora_ui/',
      '/ui/',
      'package:flutter/material.dart',
    ];

    for (final entity
        in contractsDir.listSync(recursive: true).whereType<File>()) {
      if (!entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      for (final pattern in forbidden) {
        expect(
          content.contains(pattern),
          isFalse,
          reason: '${entity.path} must not import $pattern',
        );
      }
    }
  });
}
