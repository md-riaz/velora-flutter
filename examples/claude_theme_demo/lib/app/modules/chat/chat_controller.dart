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
  bool _isDisposed = false;

  late final ConversationModel conversation;

  ChatController({MessagesDataSource? dataSource})
      : _dataSource = dataSource ?? MockMessagesDataSource();

  @override
  void onInit() {
    super.onInit();
    conversation = Get.arguments as ConversationModel;
    _loadMessages();
  }

  @override
  void onClose() {
    _isDisposed = true;
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
    if (text.isEmpty) return;

    inputController.clear();
    clearError();
    isTyping.value = true;

    try {
      // Upload any staged attachments before sending
      if (hasAttachments) await uploadAll();
      final urls = uploadedUrls;

      messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        role: MessageRole.user,
        createdAt: DateTime.now(),
      ));
      _scrollToBottom();

      final reply = await _dataSource.sendMessage(conversation.id, text, attachmentUrls: urls);
      messages.add(reply);
      attachments.clear();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isTyping.value = false;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!_isDisposed && scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
