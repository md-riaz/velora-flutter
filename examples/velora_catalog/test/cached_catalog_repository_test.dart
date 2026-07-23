import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/velora.dart';
import 'package:velora_catalog/app/data/article.dart';
import 'package:velora_catalog/app/data/catalog_schema.dart';
import 'package:velora_catalog/app/data/catalog_tables.dart';
import 'package:velora_catalog/app/data/mock_articles_remote_data_source.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_offline/velora_offline.dart';

/// Proves the demo's whole network-first read loop end to end, using the
/// app's own schema/tables/mock-remote code (not a re-implementation of it)
/// against an in-memory drift database -- exactly the way `velora_db`'s own
/// `VeloraCachedRepository` test suite does.
void main() {
  late VeloraDatabase db;
  late ToggleConnectivitySource toggleSource;
  late VeloraCachedRepository<Article, String> repository;

  Future<void> setUpWith({required bool online}) async {
    Get.testMode = true;

    // The same VeloraDbPlugin wiring the real app boots, minus GetX
    // permanence -- an in-memory drift executor keeps this hermetic and fast.
    db = await VeloraDatabase(
      databaseName: ':memory:',
      version: 1,
      migrations: [CreateCatalogSchema()],
      executor: NativeDatabase.memory(),
    ).open();
    Get.put<VeloraDatabase>(db);

    // The demo's toggle, flippable without touching a real network or
    // airplane mode -- exactly what the catalog page's Switch does.
    toggleSource = ToggleConnectivitySource(online: online);

    repository = VeloraCachedRepository<Article, String>(
      remote: MockArticlesRemoteDataSource(toggleSource),
      cache: articlesTable(),
    );
  }

  tearDown(() async {
    Get.reset();
    toggleSource.dispose();
    await db.close();
  });

  test(
    'online: index() returns the remote articles and populates the local '
    'cache table',
    () async {
      await setUpWith(online: true);

      final items = await repository.index();

      expect(items, isNotEmpty);
      expect(items.first, isA<Article>());

      final cachedCount = await articlesTable().count();
      expect(cachedCount, items.length);

      final cachedRows = await articlesTable().all();
      expect(cachedRows.map((a) => a.id), containsAll(items.map((a) => a.id)));
    },
  );

  test(
    'offline fallback: once the cache has been populated by an online '
    'index(), a subsequent offline index() serves the cached articles '
    'instead of throwing',
    () async {
      await setUpWith(online: true);

      final onlineItems = await repository.index();
      expect(onlineItems, isNotEmpty);

      // Flip offline -- the mock remote now throws a connection
      // DioException, which VeloraCachedRepository's defaultIsOfflineError
      // recognizes, falling back to the cache instead of rethrowing.
      toggleSource.setOnline(false);

      final offlineItems = await repository.index();

      expect(offlineItems, isNotEmpty);
      expect(
        offlineItems.map((a) => a.id).toSet(),
        onlineItems.map((a) => a.id).toSet(),
      );
    },
  );

  test(
    'offline, empty cache: index() returns an empty list rather than '
    'throwing, since the cache itself is empty',
    () async {
      await setUpWith(online: false);

      final items = await repository.index();

      expect(items, isEmpty);
    },
  );
}
