import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web database factory, backed by `sqflite_common_ffi_web` (IndexedDB under
/// the hood — persistence is handled transparently by the factory).
DatabaseFactory defaultVeloraDbFactory() => databaseFactoryFfiWeb;
