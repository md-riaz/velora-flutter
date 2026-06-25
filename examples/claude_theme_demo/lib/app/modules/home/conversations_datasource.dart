import 'package:velora/velora.dart';

import 'conversation_model.dart';

abstract class ConversationsDataSource {
  Future<PaginatedData<ConversationModel>> getPage(int page);
  Future<ConversationModel> create(String title);
  Future<void> delete(String id);
}

/// In-memory mock that simulates the real `/api/conversations` REST endpoints
/// via [VeloraMockApi].  Swap this with a [RemoteConversationsDataSource] that
/// calls [Velora.api] to go live without changing anything upstream.
class MockConversationsDataSource implements ConversationsDataSource {
  final List<ConversationModel> _store = _seed();

  @override
  Future<PaginatedData<ConversationModel>> getPage(int page) async {
    final raw = await VeloraMockApi.paginated(
      _store.map((c) => c.toJson()).toList(),
      page: page,
      perPage: 5,
      total: _store.length,
    );
    return PaginatedData.fromJson(
      raw,
      (v) => ConversationModel.fromJson(v as Map<String, dynamic>),
    );
  }

  @override
  Future<ConversationModel> create(String title) async {
    final created = ConversationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      lastMessage: '',
      updatedAt: DateTime.now(),
    );
    _store.insert(0, created);
    return VeloraMockApi.ok<ConversationModel>(
      created.toJson(),
      parser: (v) => ConversationModel.fromJson(v as Map<String, dynamic>),
    );
  }

  @override
  Future<void> delete(String id) async {
    await VeloraMockApi.ok<void>(null, delayMs: 200);
    _store.removeWhere((c) => c.id == id);
  }

  static List<ConversationModel> _seed() {
    final now = DateTime.now();
    return [
      ConversationModel(
        id: '1',
        title: 'Explaining quantum entanglement',
        lastMessage: 'Think of it like two coins that always land on opposite sides…',
        updatedAt: now.subtract(const Duration(minutes: 4)),
        isStarred: true,
      ),
      ConversationModel(
        id: '2',
        title: 'Python script for CSV batch processing',
        lastMessage: 'Here\'s the updated version with async support…',
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      ConversationModel(
        id: '3',
        title: 'React hooks best practices',
        lastMessage: 'useEffect cleanup functions are often overlooked…',
        updatedAt: now.subtract(const Duration(hours: 5)),
        isStarred: true,
      ),
      ConversationModel(
        id: '4',
        title: 'Planning a 2-week trip to Japan',
        lastMessage: 'For cherry blossom season, March–April in Tokyo is perfect…',
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      ConversationModel(
        id: '5',
        title: 'Debugging TypeScript generics',
        lastMessage: 'Conditional types don\'t distribute over union types the way you\'d expect…',
        updatedAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      ConversationModel(
        id: '6',
        title: 'Writing a senior engineer cover letter',
        lastMessage: 'I\'ve revised the opening paragraph to lead with impact…',
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      ConversationModel(
        id: '7',
        title: 'SQL query optimisation — slow JOIN',
        lastMessage: 'A composite index on (user_id, created_at) should cut that from 4s to under 50ms…',
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      ConversationModel(
        id: '8',
        title: 'Explain monads to a JavaScript dev',
        lastMessage: 'You\'ve been using monads already — Promise is one!…',
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }
}
