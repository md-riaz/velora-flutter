import 'package:velora/velora.dart';
import 'package:velora_offline/velora_offline.dart';

import '../../data/article.dart';
import '../../routes/app_routes.dart';

/// Drives the catalog list.
///
/// Unlike `velora_chat`'s controllers (which bind reactively to a
/// `watchQuery` stream via `listenStream` and never explicitly "load"),
/// reads here are deliberately **one-shot**: [load] fetches once, `run(...)`
/// records loading/error state around it, and the result is pushed into
/// `articles` a single time. That's the intended contrast between the two
/// example apps -- `VeloraCachedRepository` is a network-first, fetch-on-
/// demand repository, not a reactive local store, so there's no stream to
/// bind to.
class CatalogController extends VeloraController {
  final VeloraRepository<Article, String> _repository;
  final ToggleConnectivitySource toggleSource;

  final articles = <Article>[].obs;

  CatalogController({
    required VeloraRepository<Article, String> repository,
    required this.toggleSource,
  }) : _repository = repository;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Fetches the catalog once: network-first, falling back to whatever is
  /// cached locally if the (mock) API is unreachable. See
  /// `VeloraCachedRepository.index`'s dartdoc for the exact fallback rule.
  Future<void> load() async {
    await run(() async {
      final items = await _repository.index();
      articles.assignAll(items);
    }, showErrorToast: false);
  }

  /// Re-runs [load] -- used by the list's pull-to-refresh gesture. There is
  /// no separate "refresh" semantics in `VeloraCachedRepository`: every
  /// `index()` call already re-tries the network first, so a refresh is just
  /// another load. Named `reload` (not `refresh`) to avoid shadowing
  /// `GetxController.refresh()`.
  Future<void> reload() => load();

  /// Reactive online/offline flag, driven by `velora_offline`'s
  /// `ConnectivityService` (itself driven by [toggleSource]). Purely for the
  /// demo's UI banner/switch -- `VeloraCachedRepository` never looks at this
  /// itself, it detects "offline" only from the shape of the error the
  /// remote data source throws.
  RxBool get isOnline => VeloraOffline.connectivity.isOnline;

  void setOnline(bool online) => toggleSource.setOnline(online);

  void openArticle(Article article) {
    Velora.nav.to(AppRoutes.articlePath(article.id), arguments: article);
  }
}
