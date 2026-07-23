import 'package:velora_db/velora_db.dart';

import 'article.dart';

/// Binds a [VeloraTable] to the `articles` table. Kept in one place so every
/// caller (the cached repository's `cache`, tests) binds the exact same
/// `fromMap`/`toMap` pair.
VeloraTable<Article, String> articlesTable() {
  return VeloraDb.table<Article, String>(
    table: 'articles',
    fromMap: Article.fromMap,
    toMap: (article) => article.toMap(),
  );
}
