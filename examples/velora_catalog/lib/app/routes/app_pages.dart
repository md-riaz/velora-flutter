import 'package:velora/velora.dart';

import '../modules/article/article_module.dart';
import '../modules/article/article_page.dart';
import '../modules/catalog/catalog_module.dart';
import '../modules/catalog/catalog_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.catalog,
      page: () => const CatalogPage(),
      binding: BindingsBuilder(
        () => Get.lazyPut(CatalogModule.controller, fenix: true),
      ),
    ),
    GetPage(
      name: AppRoutes.article,
      page: () => const ArticlePage(),
      binding: BindingsBuilder(
        () => Get.lazyPut(ArticleModule.controller, fenix: true),
      ),
    ),
  ];
}
