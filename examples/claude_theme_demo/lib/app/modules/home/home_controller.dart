import 'package:velora/velora.dart';

import '../../routes/app_routes.dart';
import 'conversation_model.dart';
import 'conversations_datasource.dart';

/// Manages the conversations list using [VeloraPaginatedController].
///
/// Swapping [MockConversationsDataSource] with a [RemoteConversationsDataSource]
/// is the only change needed to go from prototype to production.
class HomeController extends VeloraPaginatedController<ConversationModel> {
  final ConversationsDataSource _dataSource;

  final searchQuery = ''.obs;

  HomeController({ConversationsDataSource? dataSource})
      : _dataSource = dataSource ?? MockConversationsDataSource();

  @override
  Future<PaginatedData<ConversationModel>> fetchPage(int page) =>
      _dataSource.getPage(page);

  List<ConversationModel> get filtered {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return items;
    return items.where((c) => c.title.toLowerCase().contains(q)).toList();
  }

  // NOTE: filters only the in-memory page cache, not all conversations.
  // A conversation starred on a page that hasn't been loaded yet won't
  // appear here until that page is fetched. A production implementation
  // should either load all starred conversations via a dedicated endpoint
  // (e.g. GET /conversations?starred=true) or maintain a separate starred
  // index alongside the paginated list.
  List<ConversationModel> get starred =>
      items.where((c) => c.isStarred).toList();

  void search(String query) => searchQuery.value = query;

  Future<void> startNewChat() async {
    final conv = await run(() => _dataSource.create('New conversation'));
    if (conv == null) return;
    await Velora.nav.to('/chat/${conv.id}', arguments: conv);
    await reload();
  }

  Future<void> toggleStar(String id) async {
    await run(() => _dataSource.toggleStar(id));
    if (error.value.isNotEmpty) return;
    final idx = items.indexWhere((c) => c.id == id);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(isStarred: !items[idx].isStarred);
    }
  }

  Future<void> renameConversation(String id, String title) async {
    await run(() => _dataSource.rename(id, title));
    if (error.value.isNotEmpty) return;
    final idx = items.indexWhere((c) => c.id == id);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(title: title);
    }
  }

  Future<void> deleteConversation(String id) async {
    final confirmed = await Velora.dialog.confirm(
      title: 'Delete conversation',
      message: 'This will permanently delete the conversation.',
    );
    if (!confirmed) return;
    await run(() => _dataSource.delete(id));
    if (error.value.isNotEmpty) return;
    items.removeWhere((c) => c.id == id);
    Velora.toast.success('Conversation deleted');
  }
}
