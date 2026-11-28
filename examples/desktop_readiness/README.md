# desktop_readiness

Integrated desktop readiness reference app exercising Velora's public contracts (`velora`, `velora_ui`, `velora_db`, `velora_offline`, `velora_desktop`, `velora_local_notifications`) across:

- **Adaptive shell + master-detail + controlled 2-step edit wizard**
- **Backgrounding & tray restore** (preserving navigation, selection, and unsaved wizard state)
- **Offline durable mutation queue** (`pending`, `synchronizing`, `conflict`, `permanentFailure`, idempotent replay, restart survival)
- **OS sleep/resume recovery** (coalesced signals, forced reconnect, cursor reconciliation, duplicate event deduplication)
- **Provider-neutral notification activation** (cold start, foreground, tray-hidden, duplicate activation ID deduplication, malformed payload safety)
- **Secret-redacted diagnostics**

## Support Matrix

| Target | Minimum OS | Status | Notes |
|---|---|---|---|
| Windows (x64) | Windows 10 (19041) / Windows 11 | Tier 1 (verified build & automated tests) | Tray icon & native Windows toast require packaged identity or dev AppUserModelID |

## Commands

```sh
cd examples/desktop_readiness
flutter pub get
flutter analyze
flutter test
flutter build windows --debug
```

## Windows Packaging & Identity Rules

- **Development:** Use a stable reverse-DNS `appId` (`dev.velora.desktop_readiness`) for single-instance IPC, auto-start registration, and Windows toast AUMID.
- **Production:** Sign the MSIX with a trusted certificate and match `identity_name` / `publisher` in MSIX config to the Store or enterprise signing identity so toast activation and protocol launches resolve to the installed package.
