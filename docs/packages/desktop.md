# velora_desktop

Desktop lifecycle for Velora apps — close-to-tray, single instance, protocol activation, auto-start, and suspend/resume as one event stream.

## When to use

Any Velora app that ships a desktop build (Windows, macOS, Linux) and needs at least one of:

- Close-to-tray (hide instead of quit)
- Single instance enforcement (forward second launch to the first)
- Protocol / deep-link activation
- Launch-at-login
- Sleep / wake awareness

## Architecture

```
┌──────────────────────────────────────┐
│      VeloraDesktopCoordinator        │  ← all policy, zero native code
│  (implements VeloraDesktopService)   │
├──────────┬──────────┬────────────────┤
│ WindowPort│ TrayPort │ AutoStartPort │
│ LinkPort  │PowerPort │SingleInstance │
└──────────┴──────────┴────────────────┘
      ▲                      ▲
 Real adapters          Fake (testing)
 (one per package)      (in-memory)
```

Each native capability has a **port interface** in `desktop_ports.dart`, implemented once over a real desktop package and once as an in-memory fake. The coordinator owns all policy:

- Close-to-tray when the tray icon is ready
- Tray activation / Show / Quit menu wiring
- Protocol link detection from secondary launch arguments
- Event deduplication within a configurable window
- Sleep/wake once-per-cycle reporting
- Cold-start event buffering until the first listener attaches
- Graceful degradation — a port that fails is listed in `capabilities.problems`

## Resolved packages

| Capability | Package | Version | Notes |
|---|---|---|---|
| Window | window_manager (nativeapi) | 0.6.0 | nativeapi-backed; legacy API deprecated |
| Tray | tray_manager (nativeapi) | 0.8.3 | Re-exports nativeapi TrayIcon |
| Auto-start | nativeapi `LaunchAtLogin` | 0.5.10 | Not `launch_at_startup` — see below |
| Deep links | app_links | 7.2.2 | |
| Single instance | windows_single_instance | 1.2.0 | Windows only |
| Sleep/wake | power_state_monitor | 0.1.2 | Windows only |

### Why not launch_at_startup?

`launch_at_startup ^0.5.1` depends on `win32 ^5.x`, but `flutter_secure_storage ^11.x` needs `win32 ^6.x`. The version ranges are incompatible. nativeapi already provides `LaunchAtLogin` with the same capability, and it ships `win32 ^6.x`.

## Event types

| Type | When | Key fields |
|---|---|---|
| `closeRequested` | User closes the window | `data['hidden']` — tray hide vs real close |
| `suspending` | System going to sleep | — |
| `resumed` | System woke up | — |
| `secondaryLaunch` | Another instance started | `arguments` |
| `protocolActivation` | App opened via URI scheme | `uri`, `id` |
| `notificationActivation` | App calls `reportNotificationActivation` when the user taps a notification | `id`, `data` |

## Configuration

```dart
VeloraDesktopConfig(
  appId: 'com.example.myapp',       // stable across releases
  appName: 'My App',                // shown in auto-start entry
  tray: VeloraTrayConfig(iconAsset: 'assets/tray.ico'),
  closeToTray: true,                // requires tray config
  singleInstance: true,
  protocolSchemes: {'myapp'},       // lower case, no ://
  autoStartArgument: '--autostart', // added to auto-start command
  deduplicationWindow: Duration(seconds: 2),
)
```

## Testing

Import `package:velora_desktop/src/testing.dart` for in-memory fakes of every port. The coordinator is fully testable without native dependencies or a desktop environment.
