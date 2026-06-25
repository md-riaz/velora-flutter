import 'package:flutter/widgets.dart';
import 'package:velora/velora.dart';

import '../home/conversation_model.dart';
import 'chat_message.dart';
import 'messages_datasource.dart';

class ChatController extends VeloraController with VeloraAttachmentsMixin {
  final MessagesDataSource _dataSource;

  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;
  final inputController = TextEditingController();
  final scrollController = ScrollController();
  late final ConversationModel conversation;

  ChatController({MessagesDataSource? dataSource})
      : _dataSource = dataSource ?? MockMessagesDataSource();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is! ConversationModel) {
      Get.back<void>();
      return;
    }
    conversation = args;
    _loadMessages();
  }

  @override
  void onClose() {
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _loadMessages() async {
    await run(() async {
      final loaded = await _dataSource.getMessages(conversation.id);
      messages.assignAll(loaded);
      _scrollToBottom();
    });
  }

  Future<void> sendMessage() async {
    if (isTyping.value) return;
    final text = inputController.text.trim();
    if (text.isEmpty && !hasAttachments) return;

    clearError();
    isTyping.value = true;
    ChatMessage? optimistic;

    try {
      // Upload any staged attachments before sending
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

      final reply = await _dataSource.sendMessage(conversation.id, text, attachmentUrls: urls);
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
