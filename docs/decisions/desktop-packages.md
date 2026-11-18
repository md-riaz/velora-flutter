# ADR: Desktop package selection for velora_desktop

**Status**: Accepted  
**Date**: 2024-11-11

## Context

Velora needs a desktop lifecycle package that covers window management, tray icons, single instance, deep links, auto-start, and power events. The selected packages must resolve together on the baseline (Flutter >=3.47.0, Dart >=3.13.0) without version conflicts.

## Decision

| Capability | Package | Version |
|---|---|---|
| Window | window_manager | ^0.6.0 |
| Tray | tray_manager | ^0.8.3 |
| Auto-start | nativeapi (`LaunchAtLogin`) | ^0.5.10 |
| Deep links | app_links | ^7.2.2 |
| Single instance | windows_single_instance | ^1.2.0 |
| Sleep/wake | power_state_monitor | ^0.1.2 |

### Rejected: launch_at_startup

`launch_at_startup ^0.5.1` depends on `win32 ^5.x`. `flutter_secure_storage ^11.x` (used by velora for secure token storage) depends on `win32 ^6.x`. These ranges are incompatible. nativeapi's `LaunchAtLogin` provides the same API without the conflict.

### Rejected: session lock/unlock

No stable Flutter package provides session lock/unlock on Windows. `VeloraDesktopCapabilities.lockEvents` is `false` and can be implemented later without breaking changes.

## Consequences

- All six packages resolve together with `win32 6.4.0`.
- `window_manager` 0.6 and `tray_manager` 0.8 both use nativeapi internally — no duplicate native layer.
- The port-based architecture means a package can be swapped without touching the coordinator or any app code.
