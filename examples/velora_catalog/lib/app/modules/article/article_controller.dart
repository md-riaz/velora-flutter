import 'package:velora/velora.dart';

import '../../data/article.dart';

/// Drives the article detail page: a single one-shot `show(id)` fetch,
/// network-first with a cache fallback, same as `CatalogController.load` --
/// see that class's dartdoc for why these reads are one-shot rather than
/// reactive.
class ArticleController extends VeloraController {
  final String articleId;
  final VeloraRepository<Article, String> _repository;

  /// Seeded from route arguments (if the catalog page passed the tapped
  /// [Article] straight through) so the page has something to show
  /// instantly, before [load] resolves.
  final Rx<Article?> article;

  ArticleController({
    required this.articleId,
    required VeloraRepository<Article, String> repository,
    Article? initial,
  }) : _repository = repository,
       article = Rx<Article?>(initial);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    await run(() async {
      article.value = await _repository.show(articleId);
    }, showErrorToast: false);
  }

  /// Re-runs [load] -- used by the page's pull-to-refresh gesture. Named
  /// `reload` (not `refresh`) to avoid shadowing `GetxController.refresh()`;
  /// see `CatalogController.reload`'s dartdoc for the same reasoning.
  Future<void> reload() => load();
}
