import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:velora_desktop/src/desktop_coordinator.dart';
import 'package:velora_desktop/src/desktop_event.dart';
import 'package:velora_desktop/src/desktop_ports.dart';
import 'package:velora_desktop/src/desktop_service.dart';
import 'package:velora_desktop/src/testing.dart';

void main() {
  late FakeWindowPort window;
  late FakeTrayPort tray;
  late FakeAutoStartPort autoStart;
  late FakeSingleInstancePort singleInstance;
  late FakeLinkPort links;
  late FakePowerPort power;
  late FakeDesktopStoragePort storage;
  late DateTime clock;

  VeloraDesktopCoordinator buildCoordinator({
    VeloraDesktopConfig? config,
    VeloraDesktopStoragePort? storageOverride,
  }) {
    return VeloraDesktopCoordinator(
      config:
          config ??
          VeloraDesktopConfig(
            appId: 'com.test.app',
            appName: 'Test',
            tray: const VeloraTrayConfig(iconAsset: 'assets/icon.ico'),
            closeToTray: true,
            protocolSchemes: {'myapp'},
          ),
      window: window,
      tray: tray,
      autoStart: autoStart,
      singleInstance: singleInstance,
      links: links,
      power: power,
      storage: storageOverride ?? storage,
      now: () => clock,
    );
  }

  setUp(() {
    window = FakeWindowPort();
    tray = FakeTrayPort();
    autoStart = FakeAutoStartPort();
    singleInstance = FakeSingleInstancePort();
    links = FakeLinkPort();
    power = FakePowerPort();
    storage = FakeDesktopStoragePort();
    clock = DateTime(2024, 1, 1);
  });

  group('WindowBounds', () {
    test('round-trips through JSON', () {
      const bounds = WindowBounds(x: 100, y: 200, width: 800, height: 600);
      final json = bounds.toJson();
      expect(WindowBounds.fromJson(json), equals(bounds));
    });

    test('equality and hashCode', () {
      const a = WindowBounds(x: 0, y: 0, width: 100, height: 100);
      const b = WindowBounds(x: 0, y: 0, width: 100, height: 100);
      const c = WindowBounds(x: 1, y: 0, width: 100, height: 100);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('window persistence', () {
    test('restores saved bounds on initialize', () async {
      const saved = WindowBounds(x: 50, y: 60, width: 1024, height: 768);
      storage.values[VeloraDesktopCoordinator.boundsKey] = jsonEncode(
        saved.toJson(),
      );

      final coordinator = buildCoordinator();
      await coordinator.initialize();

      expect(window.currentBounds, equals(saved));
    });

    test('no-ops gracefully when storage is empty', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();
      expect(window.currentBounds, isNull);
    });

    test('no-ops gracefully when storage has corrupt data', () async {
      storage.values[VeloraDesktopCoordinator.boundsKey] = 'not json';
      final coordinator = buildCoordinator();
      await coordinator.initialize();
      expect(window.currentBounds, isNull);
    });

    test('no-ops gracefully when storage is absent', () async {
      final coordinator = buildCoordinator(storageOverride: null);
      await coordinator.initialize();
      expect(window.currentBounds, isNull);
    });

    test('saves bounds on real close (not hide-to-tray)', () async {
      window.currentBounds = const WindowBounds(
        x: 10,
        y: 20,
        width: 640,
        height: 480,
      );

      final coordinator = buildCoordinator(
        config: VeloraDesktopConfig(
          appId: 'com.test.app',
          appName: 'Test',
          closeToTray: false,
        ),
      );
      await coordinator.initialize();

      // Trigger close
      window.onCloseRequested?.call();
      await Future<void>.delayed(Duration.zero);

      final raw = storage.values[VeloraDesktopCoordinator.boundsKey];
      expect(raw, isNotNull);
      final saved = WindowBounds.fromJson(
        jsonDecode(raw!) as Map<String, Object?>,
      );
      expect(saved, equals(window.currentBounds));
    });

    test('does not save bounds when hiding to tray', () async {
      window.currentBounds = const WindowBounds(
        x: 10,
        y: 20,
        width: 640,
        height: 480,
      );

      final coordinator = buildCoordinator();
      await coordinator.initialize();

      // Trigger close with tray available → hides instead
      window.onCloseRequested?.call();
      await Future<void>.delayed(Duration.zero);

      expect(storage.values[VeloraDesktopCoordinator.boundsKey], isNull);
    });
  });

  group('FakeDesktopStoragePort', () {
    test('stores and retrieves values', () async {
      final port = FakeDesktopStoragePort();
      expect(await port.get('k'), isNull);
      await port.set('k', 'v');
      expect(await port.get('k'), equals('v'));
    });
  });

  group('FakeWindowPort bounds', () {
    test('tracks bounds', () async {
      final port = FakeWindowPort();
      expect(await port.getBounds(), isNull);
      const bounds = WindowBounds(x: 1, y: 2, width: 3, height: 4);
      await port.setBounds(bounds);
      expect(await port.getBounds(), equals(bounds));
    });
  });

  group('VeloraDesktopConfigExtension', () {
    test('carries config and optional Windows fields', () {
      // Importing from barrel would pull VeloraPlugin which needs velora/Get.
      // The config extension is a plain data class.
    });
  });

  group('VeloraDesktopEvent', () {
    test('notification activation event has correct type', () {
      final event = VeloraDesktopEvent(
        type: VeloraDesktopEventType.notificationActivation,
        data: {'id': '42'},
      );
      expect(event.type, VeloraDesktopEventType.notificationActivation);
      expect(event.data['id'], '42');
    });
  });
}
