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
| Window storage | shared_preferences | 2.5.3 | Persists window bounds |

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
  titleBarStyle: VeloraTitleBarStyle.customTitleBar,
  windowButtonVisibility: false,
)
```

The title bar defaults to `normal` and native window buttons default to visible. Non-default settings are applied after the window attaches. `hidden` removes the native title bar; `customTitleBar` places content under a transparent native title bar where supported. The native backend currently supports that overlay on macOS; unsupported platforms report the failure in `capabilities.problems['titleBarStyle']`. Hiding the title bar also hides its native buttons in the backend; call `setWindowButtonVisibility(true)` afterward if the platform supports showing them.

At runtime use `VeloraDesktop.service.setTitleBarStyle(style)` and `VeloraDesktop.service.setWindowButtonVisibility(visible)`. Native appearance and button visibility depend on the platform. Custom `VeloraDesktopWindowPort` and `VeloraDesktopService` implementations must implement both methods.

## Plugin integration

Wire `VeloraDesktopPlugin` into your app's boot sequence:

```dart
await Velora.boot(
  config: VeloraConfig(
    // ... your config ...
    extensions: [
      VeloraDesktopConfigExtension(
        VeloraDesktopConfig(
          appId: 'com.example.myapp',
          appName: 'My App',
          tray: VeloraTrayConfig(iconAsset: 'assets/tray.ico'),
          closeToTray: true,
          protocolSchemes: {'myapp'},
        ),
        windowsNotificationGuid: '{YOUR-GUID}',  // optional
        windowsAppUserModelId: 'com.example.myapp', // optional
      ),
    ],
  ),
  plugins: [const VeloraDesktopPlugin()],
);
```

The plugin reads `VeloraDesktopConfigExtension` from `VeloraConfig.extensions`. Alternatively, pass config directly: `VeloraDesktopPlugin(config: desktopConfig)`.

On non-desktop platforms an inert service is registered — `VeloraDesktop` calls stay safe with no platform checks needed in app code.

## VeloraDesktop facade

Static accessors for the registered desktop service:

```dart
// Access the full service
VeloraDesktop.service

// Listen to desktop lifecycle events
VeloraDesktop.events.listen((event) {
  if (event.type == VeloraDesktopEventType.protocolActivation) {
    handleDeepLink(event.data['uri'] as String);
  }
});

// Query capabilities
if (VeloraDesktop.capabilities.tray) { /* ... */ }

// Window control
await VeloraDesktop.show();
await VeloraDesktop.hide();
await VeloraDesktop.quit();

// Dynamic tray updates (after setup)
await VeloraDesktop.setTrayIcon('assets/new_icon.ico');
await VeloraDesktop.setTrayTooltip('Syncing…');
await VeloraDesktop.setTrayMenuItems([
  VeloraTrayMenuItem(id: 'status', label: 'Online', enabled: false),
  VeloraTrayMenuItem(
    id: 'mute',
    label: 'Mute notifications',
    checked: false,
    onTap: () => toggleMute(),
  ),
]);
```

## Tray menu items

Custom menu items sit between the built-in Show and Quit entries. Pass them in `VeloraTrayConfig.customItems` for the initial menu, or call `setTrayMenuItems()` at any time to replace them:

```dart
VeloraTrayConfig(
  iconAsset: 'assets/tray.ico',
  customItems: [
    VeloraTrayMenuItem(id: 'pause', label: 'Pause', onTap: pause),
  ],
)
```

Each `VeloraTrayMenuItem` has:

| Field | Type | Default | Notes |
|---|---|---|---|
| `id` | `String` | required | Stable identifier |
| `label` | `String` | required | Display text |
| `onTap` | `void Function()?` | `null` | Click handler; `null` → inert |
| `enabled` | `bool` | `true` | Greyed out when `false` |
| `checked` | `bool?` | `null` | `null` → normal item; `true`/`false` → checkbox |

Throws `UnsupportedError` when tray is not available.

## Window persistence

The plugin automatically persists the window's position and size via `SharedPreferences`. Bounds are saved on close and restored on the next launch.

- **Storage key:** `velora_desktop.window_bounds`
- **Format:** JSON `{ "x": ..., "y": ..., "width": ..., "height": ... }`
- Corrupt or missing storage is handled gracefully — the OS default window size is used
- Bounds are saved only on a real close or quit, not when hiding to tray

Custom setups can pass any `VeloraDesktopStoragePort` implementation to the coordinator, or omit the `storage` parameter to disable persistence.

## Protocol / deep-link registration

`VeloraDesktopConfig.protocolSchemes` tells the coordinator which URI schemes to watch for, but the OS must know about them too. Registration is per-platform:

| Platform | Where | Example for `myapp://` |
|---|---|---|
| **Windows** | HKCU registry via the app's MSIX manifest or an installer script | `<Protocol Name="myapp" />` in `Package.appxmanifest`, or `HKCU\Software\Classes\myapp\shell\open\command` → `"C:\...\app.exe" "%1"` |
| **macOS** | `Info.plist` under `CFBundleURLTypes` | `<key>CFBundleURLSchemes</key><array><string>myapp</string></array>` |
| **Linux** | `.desktop` file `MimeType` field | `MimeType=x-scheme-handler/myapp;` and `xdg-mime default myapp.desktop x-scheme-handler/myapp` |

The `app_links` package handles incoming URIs once the scheme is registered. Cold-start links are delivered as the first event; links received while running arrive on the stream. Both are de-duplicated within the configured `deduplicationWindow`.

## Notification activation

When the user taps a desktop notification, report the activation so it joins the same ordered, de-duplicated event stream as protocol activations and secondary launches:

```dart
// From anywhere in the app:
VeloraDesktop.reportNotificationActivation(
  id: notification.id,          // unique per tap, not per notification
  data: notification.payload,   // passed through to listeners
);

// Listen alongside other desktop events:
VeloraDesktop.events.listen((event) {
  if (event.type == VeloraDesktopEventType.notificationActivation) {
    final payload = event.data; // the map you passed above
    navigateTo(payload);
  }
});
```

The bridge between your notification package (`velora_fcm`, `flutter_local_notifications`, or the system API) and the desktop event stream is a single `reportNotificationActivation` call in your notification handler. This keeps the desktop package free of notification-library dependencies.

**De-duplication**: the `id` parameter is the de-duplication key — a repeat tap on the same notification within `deduplicationWindow` is reported once. Use a unique id per *activation* (not per notification) if a second tap on the same notification should be reported again.

## Sleep / wake events

The coordinator reports `suspending` before the system sleeps and `resumed` after it wakes, once per cycle:

```dart
VeloraDesktop.events.listen((event) {
  switch (event.type) {
    case VeloraDesktopEventType.suspending:
      pauseBackgroundSync();
    case VeloraDesktopEventType.resumed:
      resumeBackgroundSync();
    default:
      break;
  }
});
```

### Platform support

| Platform | Status | Package |
|---|---|---|
| **Windows** | Supported | `power_state_monitor` — listens for `WM_POWERBROADCAST` |
| **macOS** | Not yet supported | Needs `NSWorkspace` `willSleepNotification` / `didWakeNotification` |
| **Linux** | Not yet supported | Needs D-Bus `org.freedesktop.login1.Manager` `PrepareForSleep` |

On unsupported platforms the capability degrades gracefully: `capabilities.powerEvents` is `false` and no events are emitted. The `problems` map says why.

## Testing

Import `package:velora_desktop/velora_desktop.dart` — the barrel exports `testing.dart` with in-memory fakes of every port:

- `FakeWindowPort` — tracks show/hide/close/bounds, title bar style, and button visibility
- `FakeTrayPort` — exposes `onActivate`/`onShow`/`onQuit` triggers; tracks `iconAsset`, `tooltip`, `menuItems`
- `FakeAutoStartPort` — in-memory enabled flag
- `FakeSingleInstancePort` — controllable claim success
- `FakeLinkPort` — settable initial link and stream
- `FakePowerPort` — emits power signals on demand
- `FakeDesktopStoragePort` — `Map<String, String>` backed storage

The coordinator is fully testable without native dependencies or a desktop environment.
