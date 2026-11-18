# velora_desktop

Desktop lifecycle for Velora apps: close-to-tray, single instance, protocol activation, auto-start, and suspend/resume as one event stream.

## Overview

`velora_desktop` wraps six desktop packages behind port interfaces so the coordinator (all policy, zero native code) is testable in-memory, and the app gets one `Stream<VeloraDesktopEvent>` for everything:

| Capability | Package | Port |
|---|---|---|
| Window close interception, show/hide | nativeapi 0.5.x (via window_manager 0.6) | `VeloraDesktopWindowPort` |
| Tray icon and context menu | nativeapi 0.5.x (via tray_manager 0.8) | `VeloraDesktopTrayPort` |
| Launch at login | nativeapi 0.5.x (`LaunchAtLogin`) | `VeloraDesktopAutoStartPort` |
| Single instance | windows_single_instance 1.2 | `VeloraDesktopSingleInstancePort` |
| Protocol / deep links | app_links 7.2 | `VeloraDesktopLinkPort` |
| Sleep / wake | power_state_monitor 0.1 | `VeloraDesktopPowerPort` |

## Usage

```dart
import 'package:velora_desktop/velora_desktop.dart';

final desktop = VeloraDesktopCoordinator(
  config: VeloraDesktopConfig(
    appId: 'com.example.myapp',
    appName: 'My App',
    tray: VeloraTrayConfig(iconAsset: 'assets/tray.ico'),
    closeToTray: true,
    singleInstance: true,
    protocolSchemes: {'myapp'},
  ),
  window: WindowManagerAdapter(),
  tray: TrayManagerAdapter(),
  autoStart: NativeApiAutoStartAdapter(),
  singleInstance: WindowsSingleInstanceAdapter(),
  links: AppLinksAdapter(),
  power: PowerStateMonitorAdapter(),
);

await desktop.initialize();
desktop.events.listen((event) {
  switch (event.type) {
    case VeloraDesktopEventType.closeRequested:
      // event.data['hidden'] == true when hidden to tray
    case VeloraDesktopEventType.protocolActivation:
      // event.uri holds the deep link
    case VeloraDesktopEventType.secondaryLaunch:
      // event.arguments holds the command line
    case VeloraDesktopEventType.suspending:
    case VeloraDesktopEventType.resumed:
      // lifecycle
    case VeloraDesktopEventType.notificationActivation:
      // event.id and event.data identify the notification
  }
});
```

## Testing

Use the in-memory fakes from `package:velora_desktop/src/testing.dart`:

```dart
import 'package:velora_desktop/src/testing.dart';

final window = FakeWindowPort();
final tray = FakeTrayPort();
// ... wire into VeloraDesktopCoordinator
```

## Design decisions

- **nativeapi over launch_at_startup**: `launch_at_startup ^0.5.1` requires `win32 ^5.x` which conflicts with `flutter_secure_storage ^11.x` (`win32 ^6.x`). nativeapi's `LaunchAtLogin` provides the same capability without the conflict.
- **Port architecture**: each native capability has an interface, implemented once over a real package and once as a fake, so the coordinator is testable without native dependencies.
- **Graceful degradation**: a port that fails during `initialize()` is listed in `capabilities.problems`; the rest keeps working.
