import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../data/conversation.dart';
import 'conversations_controller.dart';

/// The conversations list — the app's home screen. A `Switch` in the AppBar
/// flips [ToggleConnectivitySource]'s simulated connectivity, and a badge
/// next to it shows how many locally-written messages are still sitting in
/// the offline write outbox waiting to reach the (mock) server.
class ConversationsPage extends GetView<ConversationsController> {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Velora Chat'),
        actions: [
          Obx(() {
            final pending = controller.outboxPending.length;
            if (pending == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Tooltip(
                  message: '$pending message(s) waiting to sync',
                  child: Badge(
                    label: Text('$pending'),
                    child: const Icon(Icons.outbox_outlined),
                  ),
                ),
              ),
            );
          }),
          Obx(
            () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  controller.isOnline.value
                      ? Icons.wifi
                      : Icons.wifi_off,
                  size: 20,
                ),
                Switch(
                  value: controller.isOnline.value,
                  onChanged: controller.setOnline,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Obx(() {
        final items = controller.conversations;
        if (items.isEmpty) {
          return const Center(child: Text('No conversations yet.'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => _ConversationTile(
            conversation: items[index],
            onTap: () => controller.openConversation(items[index]),
          ),
        );
      }),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Text(
          conversation.title.isEmpty ? '?' : conversation.title[0].toUpperCase(),
          style: TextStyle(color: scheme.onPrimaryContainer),
        ),
      ),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        conversation.lastMessage ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: conversation.lastAt == null
          ? null
          : Text(
              _formatTime(conversation.lastAt!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
