import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../home/conversation_model.dart';
import '../home/conversations_datasource.dart';
import 'chat_message.dart';
import 'messages_datasource.dart';

class ChatController extends VeloraController with VeloraAttachmentsMixin {
  final MessagesDataSource _messagesDs;
  final ConversationsDataSource _conversationsDs;

  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;
  final hasEarlier = false.obs;
  final loadingEarlier = false.obs;
  final inputController = TextEditingController();
  final scrollController = ScrollController();

  late final Rx<ConversationModel> conversation;

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
    final args = Get.arguments;
    if (args is! ConversationModel) {
      Get.back<void>();
      return;
    }
    conversation = args.obs;
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
      messages.insertAll(0, page.data);
      _earlierCursor = page.nextCursor;
      hasEarlier.value = page.hasMore;
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
    final dialogController = TextEditingController(text: conversation.value.title);
    final newTitle = await Get.dialog<String>(
      _RenameDialog(controller: dialogController),
    );
    dialogController.dispose();
    if (newTitle == null || newTitle.trim().isEmpty) return;
    final trimmed = newTitle.trim();
    await run(() async {
      await _messagesDs.rename(conversation.value.id, trimmed);
      await _conversationsDs.rename(conversation.value.id, trimmed);
    });
    conversation.value = conversation.value.copyWith(title: trimmed);
    Velora.toast.success('Renamed');
  }

  Future<void> toggleStar() async {
    final newStarred = !conversation.value.isStarred;
    conversation.value = conversation.value.copyWith(isStarred: newStarred);
    await _messagesDs.toggleStar(conversation.value.id);
    await _conversationsDs.toggleStar(conversation.value.id);
    Velora.toast.success(newStarred ? 'Added to starred' : 'Removed from starred');
  }

  Future<void> clearHistory() async {
    final confirmed = await Velora.dialog.confirm(
      title: 'Clear history',
      message: 'This will remove all messages from this conversation.',
    );
    if (!confirmed) return;
    await _messagesDs.clearMessages(conversation.value.id);
    messages.clear();
    hasEarlier.value = false;
    _earlierCursor = null;
    Velora.toast.success('Chat history cleared');
  }

  Future<void> deleteConversation() async {
    final confirmed = await Velora.dialog.confirm(
      title: 'Delete conversation',
      message: 'This will permanently delete this conversation and all its messages.',
    );
    if (!confirmed) return;
    await _messagesDs.delete(conversation.value.id);
    await _conversationsDs.delete(conversation.value.id);
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

// ---------------------------------------------------------------------------
// Rename dialog
// ---------------------------------------------------------------------------

class _RenameDialog extends StatelessWidget {
  final TextEditingController controller;
  const _RenameDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename conversation'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Conversation title'),
        onSubmitted: (v) => Get.back(result: v),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<String>(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Get.back(result: controller.text),
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
