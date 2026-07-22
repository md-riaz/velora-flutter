import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Native default executor: a `NativeDatabase` (via `package:sqlite3`,
/// dlopen-ing the platform's SQLite) running in a background isolate via
/// [NativeDatabase.createInBackground].
///
/// [databaseName] is resolved relative to the app's documents directory
/// (via `path_provider`) unless it's already an absolute path -- mirroring
/// the old sqflite factory's behavior of resolving a bare filename like
/// `'app.db'` to a sensible per-app location. Wrapped in a [LazyDatabase] so
/// that directory lookup (`getApplicationDocumentsDirectory`, itself async
/// and platform-channel-backed) only happens once the database is first
/// used, not at construction time.
QueryExecutor defaultVeloraDbExecutor(String databaseName) {
  return LazyDatabase(() async {
    final path = p.isAbsolute(databaseName)
        ? databaseName
        : p.join(
            (await getApplicationDocumentsDirectory()).path,
            databaseName,
          );
    return NativeDatabase.createInBackground(File(path));
  });
}
