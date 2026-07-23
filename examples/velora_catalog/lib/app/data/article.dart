/// A single catalog article, backed by the `articles` table.
///
/// `fromMap`/`toMap` keys mirror the column names exactly, so an `Article`
/// round-trips straight through `VeloraTable<Article, String>` (the cache
/// side of `VeloraCachedRepository`) without any translation layer, and
/// straight through the mock remote data source's seeded rows the same way.
class Article {
  final String id;
  final String title;
  final String summary;
  final String author;
  final int updatedAt;

  const Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.author,
    required this.updatedAt,
  });

  DateTime get updatedAtDate => DateTime.fromMillisecondsSinceEpoch(updatedAt);

  factory Article.fromMap(Map<String, dynamic> row) {
    final updatedAtValue = row['updated_at'];
    return Article(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      summary: row['summary']?.toString() ?? '',
      author: row['author']?.toString() ?? '',
      updatedAt: updatedAtValue == null
          ? 0
          : (updatedAtValue is int
              ? updatedAtValue
              : int.parse(updatedAtValue.toString())),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'author': author,
      'updated_at': updatedAt,
    };
  }
}
