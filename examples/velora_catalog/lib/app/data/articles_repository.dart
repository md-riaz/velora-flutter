import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_offline/velora_offline.dart';

import 'article.dart';
import 'catalog_tables.dart';
import 'mock_articles_remote_data_source.dart';

/// Builds the network-first [VeloraCachedRepository] backing the catalog.
///
/// Kept in one place so every caller (both modules, tests) wires the exact
/// same pieces together: [MockArticlesRemoteDataSource] as the remote source
/// of truth, `articlesTable()` as the local read-through cache. Mirrors
/// `velora_chat`'s `*_tables.dart` helpers, which do the same thing for a
/// bound `VeloraTable`.
///
/// [toggleSource] is passed in explicitly by the caller (each module's
/// factory, resolved from the composition root's `Get.put` in `main.dart`)
/// rather than resolved here via `Get.find` -- the data layer takes plain
/// constructor-injected dependencies, the same way `MockArticlesRemoteDataSource`
/// itself does.
VeloraRepository<Article, String> articlesRepository(
  ToggleConnectivitySource toggleSource,
) {
  return VeloraCachedRepository<Article, String>(
    remote: MockArticlesRemoteDataSource(toggleSource),
    cache: articlesTable(),
  );
}
