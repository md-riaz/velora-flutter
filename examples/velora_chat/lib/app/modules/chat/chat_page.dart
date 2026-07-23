import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../data/message.dart';
import 'chat_controller.dart';

/// A single conversation's message thread — WhatsApp-style bubbles, an
/// offline banner driven by the demo's connectivity toggle, and a compose
/// bar that writes through `velora_offline`'s offline-first repository.
class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Velora.nav.back(),
        ),
        title: Text(controller.conversationTitle),
      ),
      body: Column(
        children: [
          Obx(() {
            if (controller.isOnline.value) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You're offline — messages will send when you "
                      'reconnect.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Expanded(
            child: Obx(() {
              final items = controller.messages;
              if (items.isEmpty) {
                return const Center(child: Text('No messages yet. Say hi!'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) => _MessageBubble(
                  message: items[index],
                ),
              );
            }),
          ),
          _ComposeBar(controller: controller),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOutgoing = message.outgoing;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOutgoing ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.body,
              style: TextStyle(
                color: isOutgoing
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            if (isOutgoing) ...[
              const SizedBox(height: 2),
              Icon(
                message.isPending ? Icons.schedule : Icons.done,
                size: 14,
                color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComposeBar extends StatelessWidget {
  final ChatController controller;

  const _ComposeBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.composeController,
                textInputAction: TextInputAction.send,
                onSubmitted: controller.send,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: () => controller.send(controller.composeController.text),
            ),
          ],
        ),
      ),
    );
  }
}
