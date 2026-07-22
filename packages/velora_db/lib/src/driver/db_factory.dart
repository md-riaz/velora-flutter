/// Conditional export of the platform-appropriate default drift
/// [QueryExecutor][QE] factory (native `NativeDatabase` on iOS/Android/
/// desktop, `WasmDatabase` on Web), so `velora_db` never pulls web-only or
/// `dart:io`-only code into the wrong build.
///
/// Both branches expose the same top-level symbol,
/// `QueryExecutor defaultVeloraDbExecutor(String databaseName)`, so callers
/// can import this file without caring which platform they're building for.
///
/// [QE]: package:drift/drift.dart
library;

export 'db_factory_io.dart' if (dart.library.js_interop) 'db_factory_web.dart';
