import 'package:velora/velora.dart';

import '../../data/article.dart';
import '../../data/articles_repository.dart';
import 'article_controller.dart';

/// Builds an [ArticleController] with its dependencies constructed
/// explicitly (constructor DI): the article id comes from the route
/// parameter GetX resolved for this page, and an already-known [Article]
/// (if the catalog page passed one via route arguments) seeds the page
/// instantly while [ArticleController.load] re-fetches it network-first.
class ArticleModule {
  static ArticleController controller() {
    final id = Get.parameters['id'] ?? '';
    final args = Get.arguments;

    return ArticleController(
      articleId: id,
      repository: articlesRepository(),
      initial: args is Article ? args : null,
    );
  }
}
