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
/// Result type for cursor/keyset-based pagination.
///
/// [C] is the cursor type — typically [String] (opaque token) or [int] (ID).
///
/// ```dart
/// CursorPage<UserModel, String>(
///   data: users,
///   nextCursor: response.meta['next_cursor'],
/// )
/// ```
class CursorPage<T, C> {
  final List<T> data;

  /// Cursor for the next page. `null` when there are no more pages.
  final C? nextCursor;

  const CursorPage({required this.data, this.nextCursor});

  bool get hasMore => nextCursor != null;
}

/// Base controller for screens backed by a cursor/keyset-paginated data source.
///
/// Subclasses implement [fetchNextPage] with the cursor from the previous
/// response (null on the first call).  The controller handles accumulation,
/// load-more, and pull-to-refresh.
///
/// ```dart
/// class ActivityController extends VeloraCursorController<ActivityModel, String> {
///   @override
///   Future<CursorPage<ActivityModel, String>> fetchNextPage(String? cursor) =>
///       _service.getActivity(cursor: cursor);
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
///     return ActivityTile(activity: controller.items[i]);
///   },
/// ))
/// ```
abstract class VeloraCursorController<T, C> extends VeloraController {
  final items = <T>[].obs;
  final isRefreshing = false.obs;
  C? _nextCursor;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  /// Fetch the next page.  [cursor] is null on the first call and non-null
  /// on subsequent calls.  Implement in your subclass.
  Future<CursorPage<T, C>> fetchNextPage(C? cursor);

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  /// Clears and reloads from the beginning.  Safe to call on pull-to-refresh.
  Future<void> reload() async {
    if (isRefreshing.value || loading.value) return;
    isRefreshing.value = true;
    _nextCursor = null;
    _hasMore = true;
    items.clear();
    clearError();
    await _loadPage();
    isRefreshing.value = false;
  }

  Future<void> loadMore() async {
    if (loading.value || !_hasMore) return;
    await _loadPage();
  }

  Future<void> _loadPage() async {
    final cursor = _nextCursor;
    await run(() async {
      final result = await fetchNextPage(cursor);
      items.addAll(result.data);
      _nextCursor = result.nextCursor;
      _hasMore = result.hasMore;
    });
  }
}

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
