import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqlite_api.dart';

/// Native (iOS/Android/desktop) database factory, backed by `sqflite`'s
/// platform channel implementation.
DatabaseFactory defaultVeloraDbFactory() => sqflite.databaseFactory;
