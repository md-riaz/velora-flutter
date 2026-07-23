import 'package:velora/velora.dart';
import 'package:velora_offline/velora_offline.dart';

import '../../data/articles_repository.dart';
import 'catalog_controller.dart';

/// Builds a [CatalogController] with its dependencies constructed explicitly
/// (constructor DI), rather than the controller reaching into `Get.find`/
/// service locators itself.
class CatalogModule {
  static CatalogController controller() {
    final toggleSource = Get.find<ToggleConnectivitySource>();

    return CatalogController(
      repository: articlesRepository(toggleSource),
      toggleSource: toggleSource,
    );
  }
}
