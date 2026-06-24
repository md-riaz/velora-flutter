import 'package:get/get.dart';

import '../support/paginated_data.dart';
import '../validation/velora_controller.dart';

/// Base controller for screens backed by a paginated data source.
///
/// Subclasses implement [fetchPage] to call their repository.  The controller
/// handles paging state, incremental loading, and pull-to-refresh out of the
/// box.
///
/// Usage:
/// ```dart
/// class UsersController extends VeloraPaginatedController<UserModel> {
///   @override
///   Future<PaginatedData<UserModel>> fetchPage(int page) =>
///       _service.getUsers(page: page);
/// }
///
/// // In the view:
/// Obx(() => ListView.builder(
///   itemCount: controller.items.length + (controller.hasMore ? 1 : 0),
///   itemBuilder: (ctx, i) {
///     if (i == controller.items.length) {
///       controller.loadMore();
///       return const CircularProgressIndicator.adaptive();
///     }
///     return UserTile(user: controller.items[i]);
///   },
/// ))
/// ```
abstract class VeloraPaginatedController<T> extends VeloraController {
  final items = <T>[].obs;
  final isRefreshing = false.obs;
  int _currentPage = 1;
  int _lastPage = 1;

  bool get hasMore => _currentPage <= _lastPage;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;

  /// Fetch one page from the data source.  Implement in your subclass.
  Future<PaginatedData<T>> fetchPage(int page);

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  /// Clears and reloads from page 1.  Safe to call on pull-to-refresh.
  ///
  /// Named `reload` (not `refresh`) to avoid shadowing
  /// `ListNotifier.refresh()` inherited from GetX.
  Future<void> reload() async {
    if (isRefreshing.value || loading.value) return;
    isRefreshing.value = true;
    _currentPage = 1;
    _lastPage = 1;
    items.clear();
    clearError();
    await _loadNextPage();
    isRefreshing.value = false;
  }

  Future<void> loadMore() async {
    if (loading.value || !hasMore) return;
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    final page = _currentPage;
    await run(() async {
      final result = await fetchPage(page);
      items.addAll(result.data);
      _lastPage = result.lastPage;
      _currentPage = result.currentPage + 1;
    });
  }
}
