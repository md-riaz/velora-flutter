import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_offline/velora_offline.dart';

import '../../data/conversation.dart';
import '../../routes/app_routes.dart';

/// Drives the conversations list: a reactive read straight from `velora_db`
/// (newest activity first), plus the connectivity toggle and outbox badge
/// that make the offline-first story visible in the demo.
class ConversationsController extends VeloraController {
  final VeloraTable<Conversation, String> _table;
  final ToggleConnectivitySource toggleSource;

  final conversations = <Conversation>[].obs;

  ConversationsController({
    required VeloraTable<Conversation, String> table,
    required this.toggleSource,
  }) : _table = table;

  @override
  void onInit() {
    super.onInit();
    listenStream(
      _table.watchQuery(_table.query().orderBy('last_at', desc: true)),
      conversations.assignAll,
    );
  }

  /// Reactive online/offline flag, driven by `velora_offline`'s
  /// `ConnectivityService` (itself driven by [toggleSource]).
  RxBool get isOnline => VeloraOffline.connectivity.isOnline;

  /// Reactive outbox: every locally-written message still waiting to reach
  /// the (mock) server shows up here until it's flushed.
  RxList<OfflineRequest> get outboxPending => VeloraOffline.queue.pending;

  void setOnline(bool online) => toggleSource.setOnline(online);

  void openConversation(Conversation conversation) {
    Velora.nav.to(
      AppRoutes.chatPath(conversation.id),
      arguments: conversation,
    );
  }
}
