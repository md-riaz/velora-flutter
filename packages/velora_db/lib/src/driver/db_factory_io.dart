import 'dart:io';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Native database factory: `sqflite`'s platform channel implementation on
/// iOS/Android/macOS, or `sqflite_common_ffi`'s FFI implementation on
/// Windows/Linux, where `sqflite` has no platform channel plugin and
/// `sqflite.databaseFactory` throws `MissingPluginException`.
DatabaseFactory defaultVeloraDbFactory() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return sqflite.databaseFactory;
}
