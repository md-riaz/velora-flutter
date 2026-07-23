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
VeloraRepository<Article, String> articlesRepository() {
  return VeloraCachedRepository<Article, String>(
    remote: MockArticlesRemoteDataSource(Get.find<ToggleConnectivitySource>()),
    cache: articlesTable(),
  );
}
