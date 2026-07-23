import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_offline/velora_offline.dart';

import '../../data/conversation.dart';
import '../../data/message.dart';

/// Drives a single conversation's message thread.
///
/// Reads come straight from `velora_offline`'s
/// `VeloraOfflineFirstRepository.watchQuery` — reactive, local-first, and
/// fully functional offline. [send] writes the new message locally first
/// (so it shows up instantly with `status: 'pending'`) and enqueues it onto
/// the write outbox; [MockChatServerInterceptor] flips it to `'sent'` once
/// the (simulated) server acknowledges it.
class ChatController extends VeloraController {
  static const _uuid = Uuid();

  final String conversationId;
  final String conversationTitle;
  final VeloraOfflineFirstRepository<Message, String> _messages;
  final VeloraTable<Conversation, String> _conversations;
  final ToggleConnectivitySource toggleSource;

  final messages = <Message>[].obs;
  final composeController = TextEditingController();

  ChatController({
    required this.conversationId,
    required this.conversationTitle,
    required VeloraOfflineFirstRepository<Message, String> messagesRepository,
    required VeloraTable<Conversation, String> conversationsTable,
    required this.toggleSource,
  })  : _messages = messagesRepository,
        _conversations = conversationsTable;

  @override
  void onInit() {
    super.onInit();
    listenStream(
      _messages.watchQuery(
        _messages
            .query()
            .where('conversation_id', conversationId)
            .orderBy('created_at'),
      ),
      messages.assignAll,
    );
  }

  @override
  void onClose() {
    composeController.dispose();
    super.onClose();
  }

  /// Reactive online/offline flag, driven by `velora_offline`'s
  /// `ConnectivityService`.
  RxBool get isOnline => VeloraOffline.connectivity.isOnline;

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    final message = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      body: trimmed,
      outgoing: true,
      status: 'pending',
      createdAt: now,
    );

    // Local write + outbox enqueue (and an immediate flush if already
    // online) — see VeloraOfflineFirstRepository.store's dartdoc.
    await _messages.store(message.toMap());

    // Keep the conversations list preview in sync so it doesn't show a
    // stale last message.
    await _conversations.update(conversationId, {
      'last_message': trimmed,
      'last_at': now.millisecondsSinceEpoch,
    });

    // Only clear the compose field once both writes have succeeded, so a
    // thrown error leaves the user's typed text intact instead of losing it.
    composeController.clear();
  }
}
