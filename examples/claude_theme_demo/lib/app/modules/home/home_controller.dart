import 'package:velora/velora.dart';

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

  void search(String query) => searchQuery.value = query;

  Future<void> startNewChat() async {
    final conv = await _dataSource.create('New conversation');
    items.insert(0, conv);
    Velora.nav.to('/chat', arguments: conv);
  }
}
