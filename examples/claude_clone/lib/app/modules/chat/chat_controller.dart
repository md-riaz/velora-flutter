import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../home/conversation_model.dart';
import '../home/conversations_datasource.dart';
import 'chat_message.dart';
import 'messages_datasource.dart';
import 'widgets/rename_dialog.dart';

class ChatController extends VeloraController with VeloraAttachmentsMixin {
  final MessagesDataSource _messagesDs;
  final ConversationsDataSource _conversationsDs;

  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;
  final hasEarlier = false.obs;
  final loadingEarlier = false.obs;
  final inputController = TextEditingController();
  final scrollController = ScrollController();

  // Eagerly initialized (not late final) — avoids LateInitializationError that corrupts GetX proxy state before _bootstrapFromId completes.
  final conversation = Rx<ConversationModel>(ConversationModel(
    id: '',
    title: '',
    lastMessage: '',
    updatedAt: DateTime.utc(2020),
  ));

  /// ID of the oldest loaded message — used as cursor for the next
  /// "load earlier" request.
  String? _earlierCursor;

  ChatController({
    MessagesDataSource? messagesDs,
    ConversationsDataSource? conversationsDs,
  })  : _messagesDs = messagesDs ?? MockMessagesDataSource(),
        _conversationsDs = conversationsDs ?? MockConversationsDataSource();

  @override
  void onInit() {
    super.onInit();
    final id = Get.parameters['id'];
    if (id == null || id.isEmpty) {
      Get.back<void>();
      return;
    }
    final args = Get.arguments;
    if (args is ConversationModel && args.id == id) {
      conversation.value = args;
      _loadMessages();
    } else {
      conversation.value = ConversationModel(
        id: id,
        title: 'Loading...',
        lastMessage: '',
        updatedAt: DateTime.utc(2020),
      );
      _bootstrapFromId(id);
    }
  }

  Future<void> _bootstrapFromId(String id) async {
    ConversationModel? conv;
    await run(() async {
      conv = await _conversationsDs.getById(id);
    });
    if (conv == null || error.value.isNotEmpty) {
      Get.back<void>();
      return;
    }
    conversation.value = conv!;
    _loadMessages();
  }

  @override
  void onClose() {
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Message loading
  // ---------------------------------------------------------------------------

  Future<void> _loadMessages() async {
    await run(() async {
      final page = await _messagesDs.getPage(conversation.value.id);
      messages.assignAll(page.data);
      _earlierCursor = page.nextCursor;
      hasEarlier.value = page.hasMore;
      _scrollToBottom();
    });
  }

  /// Loads the next earlier page and prepends it to [messages].
  Future<void> loadEarlier() async {
    if (loadingEarlier.value || !hasEarlier.value) return;
    loadingEarlier.value = true;
    try {
      final page = await _messagesDs.getPage(
        conversation.value.id,
        beforeId: _earlierCursor,
      );
      // Capture the current max extent before prepending so we can restore
      // the reading position — without this the viewport snaps upward.
      final prevMax = scrollController.hasClients
          ? scrollController.position.maxScrollExtent
          : 0.0;
      messages.insertAll(0, page.data);
      _earlierCursor = page.nextCursor;
      hasEarlier.value = page.hasMore;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isClosed && scrollController.hasClients) {
          final delta = scrollController.position.maxScrollExtent - prevMax;
          scrollController.jumpTo(scrollController.offset + delta);
        }
      });
    } catch (e) {
      error.value = e.toString();
    } finally {
      loadingEarlier.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Sending
  // ---------------------------------------------------------------------------

  Future<void> sendMessage() async {
    if (isTyping.value) return;
    final text = inputController.text.trim();
    if (text.isEmpty && !hasAttachments) return;

    clearError();
    isTyping.value = true;
    ChatMessage? optimistic;

    try {
      if (hasAttachments) await uploadAll();
      final urls = uploadedUrls;

      optimistic = ChatMessage(
        id: UniqueKey().toString(),
        content: text,
        role: MessageRole.user,
        createdAt: DateTime.now(),
      );
      messages.add(optimistic);
      _scrollToBottom();

      final reply = await _messagesDs.sendMessage(
        conversation.value.id,
        text,
        attachmentUrls: urls,
      );
      messages.add(reply);
      inputController.clear();
      attachments.clear();

      // The primary send succeeded — don't roll back the user message if a
      // non-fatal secondary side effect (preview update) throws below.
      optimistic = null;

      // Keep the conversation's list preview in sync so the home list doesn't
      // show a stale last message. Persisted through the conversations data
      // source (single write) rather than mutating a second store by hand.
      final preview = text.isNotEmpty ? text : 'Attachment';
      final updatedAt = DateTime.now();
      await _conversationsDs.updateLastMessage(
        conversation.value.id,
        preview,
        updatedAt: updatedAt,
      );
      conversation.value = conversation.value.copyWith(
        lastMessage: preview,
        updatedAt: updatedAt,
      );
    } catch (e) {
      if (optimistic != null) messages.remove(optimistic);
      error.value = e.toString();
    } finally {
      isTyping.value = false;
      _scrollToBottom();
    }
  }

  // ---------------------------------------------------------------------------
  // Conversation mutations
  // ---------------------------------------------------------------------------

  Future<void> renameConversation() async {
    final newTitle = await Get.dialog<String>(
      RenameConversationDialog(initialTitle: conversation.value.title),
    );
    if (newTitle == null || newTitle.trim().isEmpty) return;
    final trimmed = newTitle.trim();
    await run(() async {
      await _messagesDs.rename(conversation.value.id, trimmed);
      await _conversationsDs.rename(conversation.value.id, trimmed);
    });
    if (error.value.isNotEmpty) return;
    conversation.value = conversation.value.copyWith(title: trimmed);
    Velora.toast.success('Renamed');
  }

  Future<void> toggleStar() async {
    final newStarred = !conversation.value.isStarred;
    conversation.value = conversation.value.copyWith(isStarred: newStarred);
    await run(() async {
      await _messagesDs.toggleStar(conversation.value.id);
      await _conversationsDs.toggleStar(conversation.value.id);
    });
    if (error.value.isNotEmpty) {
      conversation.value = conversation.value.copyWith(isStarred: !newStarred);
      return;
    }
    Velora.toast.success(newStarred ? 'Added to starred' : 'Removed from starred');
  }

  Future<void> clearHistory() async {
    if (isTyping.value) {
      Velora.toast.info('Wait for the current reply to finish');
      return;
    }
    final confirmed = await Velora.dialog.confirm(
      title: 'Clear history',
      message: 'This will remove all messages from this conversation.',
    );
    if (!confirmed) return;
    await run(() async {
      await _messagesDs.clearMessages(conversation.value.id);
      await _conversationsDs.clearHistory(conversation.value.id);
    });
    if (error.value.isNotEmpty) return;
    messages.clear();
    hasEarlier.value = false;
    _earlierCursor = null;
    conversation.value = conversation.value.copyWith(lastMessage: '');
    Velora.toast.success('Chat history cleared');
  }

  Future<void> deleteConversation() async {
    final confirmed = await Velora.dialog.confirm(
      title: 'Delete conversation',
      message: 'This will permanently delete this conversation and all its messages.',
    );
    if (!confirmed) return;
    await run(() async {
      await _messagesDs.delete(conversation.value.id);
      await _conversationsDs.delete(conversation.value.id);
    });
    if (error.value.isNotEmpty) return;
    Velora.nav.back();
    Velora.toast.success('Conversation deleted');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _scrollToBottom() {
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!isClosed && scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
