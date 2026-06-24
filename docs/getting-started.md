# Getting Started

Create a Velora app, configure `VeloraConfig`, then call `Velora.boot` before `runApp`.

```dart
await Velora.boot(
  config: const VeloraConfig(
    appName: 'Demo',
    apiBaseUrl: 'https://api.example.com/api',
  ),
);
```

For a Laravel backend, expose Sanctum-style bearer-token endpoints for login, logout, and the current user. For local UI/API testing, the starter app can run in mock mode: demo login writes a token/user into Velora storage and feature modules bind mock data sources instead of network-backed data sources.
