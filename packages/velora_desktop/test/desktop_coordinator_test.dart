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
  late DateTime clock;

  VeloraDesktopCoordinator buildCoordinator({
    VeloraDesktopConfig? config,
  }) {
    return VeloraDesktopCoordinator(
      config: config ??
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
    clock = DateTime(2024, 1, 1);
  });

  group('initialize', () {
    test('sets up all ports and reports capabilities', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      expect(coordinator.capabilities.window, isTrue);
      expect(coordinator.capabilities.tray, isTrue);
      expect(coordinator.capabilities.autoStart, isTrue);
      expect(coordinator.capabilities.singleInstance, isTrue);
      expect(coordinator.capabilities.protocolLinks, isTrue);
      expect(coordinator.capabilities.powerEvents, isTrue);
      expect(coordinator.capabilities.lockEvents, isFalse);
      expect(coordinator.capabilities.problems, isEmpty);

      expect(window.attached, isTrue);
      expect(tray.ready, isTrue);
      expect(autoStart.ready, isTrue);
      expect(singleInstance.claimed, isTrue);
      expect(power.started, isTrue);
    });

    test('is idempotent', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();
      await coordinator.initialize();
      expect(coordinator.capabilities.window, isTrue);
    });

    test('degrades gracefully when tray is unsupported', () async {
      tray.supported = false;
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      expect(coordinator.capabilities.tray, isFalse);
      expect(coordinator.capabilities.window, isTrue);
      expect(coordinator.capabilities.problems, contains('tray'));
    });

    test('degrades gracefully when power is unsupported', () async {
      power.supported = false;
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      expect(coordinator.capabilities.powerEvents, isFalse);
      expect(coordinator.capabilities.problems, contains('powerEvents'));
    });
  });

  group('close-to-tray', () {
    test('hides window when close-to-tray is on and tray is ready', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      // Simulate a close request
      final mayClose = window.onCloseRequested!();
      expect(mayClose, isFalse);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].type, VeloraDesktopEventType.closeRequested);
      expect(events[0].data['hidden'], isTrue);
    });

    test('closes window when close-to-tray is off', () async {
      final coordinator = buildCoordinator(
        config: const VeloraDesktopConfig(
          appId: 'com.test.app',
          appName: 'Test',
          closeToTray: false,
        ),
      );
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      final mayClose = window.onCloseRequested!();
      expect(mayClose, isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].data['hidden'], isFalse);
    });

    test('closes window when tray setup failed', () async {
      tray.supported = false;
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      final mayClose = window.onCloseRequested!();
      expect(mayClose, isTrue);
    });
  });

  group('quit', () {
    test('always closes, bypassing close-to-tray', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();
      await coordinator.quit();

      // The next close request from window.close() should return true
      final mayClose = window.onCloseRequested!();
      expect(mayClose, isTrue);
    });
  });

  group('secondary launch', () {
    test('emits secondaryLaunch and shows window', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      singleInstance.onSecondaryLaunch!(['--new-window']);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].type, VeloraDesktopEventType.secondaryLaunch);
      expect(events[0].arguments, ['--new-window']);
    });

    test('detects protocol link in secondary launch arguments', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      singleInstance.onSecondaryLaunch!(['myapp://open/chat']);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].type, VeloraDesktopEventType.protocolActivation);
      expect(events[0].uri, Uri.parse('myapp://open/chat'));
    });
  });

  group('links', () {
    test('emits protocolActivation from link stream', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      links.add(Uri.parse('myapp://deep/link'));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].type, VeloraDesktopEventType.protocolActivation);
      expect(events[0].uri, Uri.parse('myapp://deep/link'));
    });

    test('delivers initial link from cold start', () async {
      links = FakeLinkPort(initial: Uri.parse('myapp://cold'));
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].type, VeloraDesktopEventType.protocolActivation);
      expect(events[0].uri, Uri.parse('myapp://cold'));
    });
  });

  group('deduplication', () {
    test('suppresses duplicate link within deduplication window', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      links.add(Uri.parse('myapp://dup'));
      await Future<void>.delayed(Duration.zero);
      links.add(Uri.parse('myapp://dup'));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
    });

    test('allows same link after deduplication window expires', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      links.add(Uri.parse('myapp://dup'));
      await Future<void>.delayed(Duration.zero);

      clock = clock.add(const Duration(seconds: 3));
      links.add(Uri.parse('myapp://dup'));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
    });
  });

  group('power events', () {
    test('emits suspending and resumed', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      power.add(VeloraPowerSignal.suspending);
      await Future<void>.delayed(Duration.zero);
      power.add(VeloraPowerSignal.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events[0].type, VeloraDesktopEventType.suspending);
      expect(events[1].type, VeloraDesktopEventType.resumed);
    });

    test('reports suspending once per sleep cycle', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      power.add(VeloraPowerSignal.suspending);
      await Future<void>.delayed(Duration.zero);
      power.add(VeloraPowerSignal.suspending);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
    });

    test('reports resumed once per wake', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      power.add(VeloraPowerSignal.suspending);
      await Future<void>.delayed(Duration.zero);
      power.add(VeloraPowerSignal.resumed);
      await Future<void>.delayed(Duration.zero);
      power.add(VeloraPowerSignal.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
    });
  });

  group('notification activation', () {
    test('emits notificationActivation event', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      coordinator.reportNotificationActivation(
        id: 'notif-1',
        data: {'action': 'reply'},
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].type, VeloraDesktopEventType.notificationActivation);
      expect(events[0].id, 'notif-1');
      expect(events[0].data['action'], 'reply');
    });

    test('deduplicates same notification within window', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);

      coordinator.reportNotificationActivation(id: 'notif-1');
      coordinator.reportNotificationActivation(id: 'notif-1');
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
    });
  });

  group('auto-start', () {
    test('setAutoStart and isAutoStartEnabled round-trip', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      expect(await coordinator.isAutoStartEnabled(), isFalse);
      await coordinator.setAutoStart(true);
      expect(await coordinator.isAutoStartEnabled(), isTrue);
      await coordinator.setAutoStart(false);
      expect(await coordinator.isAutoStartEnabled(), isFalse);
    });

    test('setAutoStart throws when unsupported', () async {
      autoStart.supported = false;
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      expect(
        () => coordinator.setAutoStart(true),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('cold-start buffering', () {
    test('buffers events before first listener', () async {
      links = FakeLinkPort(initial: Uri.parse('myapp://buffered'));
      final coordinator = buildCoordinator();
      await coordinator.initialize();

      // Events emitted during initialize but no listener yet
      final events = <VeloraDesktopEvent>[];
      coordinator.events.listen(events.add);
      await Future<void>.delayed(Duration.zero);

      expect(events.any((e) => e.uri == Uri.parse('myapp://buffered')), isTrue);
    });
  });

  group('dispose', () {
    test('stops ports and closes event stream', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();
      await coordinator.dispose();

      expect(tray.disposed, isTrue);
      expect(window.attached, isFalse);
    });

    test('is idempotent', () async {
      final coordinator = buildCoordinator();
      await coordinator.initialize();
      await coordinator.dispose();
      await coordinator.dispose();
    });
  });

  group('launchedByAutoStart', () {
    test('true when launch arguments contain the auto-start flag', () {
      const config = VeloraDesktopConfig(
        appId: 'test',
        appName: 'Test',
        launchArguments: ['--autostart'],
      );
      expect(config.launchedByAutoStart, isTrue);
    });

    test('false when no auto-start flag', () {
      const config = VeloraDesktopConfig(
        appId: 'test',
        appName: 'Test',
      );
      expect(config.launchedByAutoStart, isFalse);
    });
  });
}
