import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web default executor: a `WasmDatabase`, resolved via [WasmDatabase.open]
/// which probes the browser for the best available persistence backend
/// (OPFS when available, falling back to IndexedDB) and runs the database in
/// a Web Worker.
///
/// Requires two static assets to be served alongside the app -- see
/// `docs/packages/db.md`'s "Cross-platform" section for exactly where they
/// come from and where to put them:
///
/// - `sqlite3.wasm` (the compiled SQLite WebAssembly module)
/// - `drift_worker.js` (the worker script that hosts the database)
///
/// Wrapped in a [LazyDatabase] so the async probing/worker-spawning only
/// happens once the database is first used, not at construction time.
QueryExecutor defaultVeloraDbExecutor(String databaseName) {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: databaseName,
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
