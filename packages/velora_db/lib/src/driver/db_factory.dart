/// Conditional export of the platform-appropriate default [DatabaseFactory][DF]
/// (native sqflite on iOS/Android/desktop, `sqflite_common_ffi_web` on Web),
/// so `velora_db` never pulls web-only or platform-channel-only code into the
/// wrong build.
///
/// Both branches expose the same top-level symbol,
/// `DatabaseFactory defaultVeloraDbFactory()`, so callers can import this file
/// without caring which platform they're building for.
///
/// [DF]: package:sqflite_common/sqlite_api.dart
library;

export 'db_factory_io.dart' if (dart.library.js_interop) 'db_factory_web.dart';
