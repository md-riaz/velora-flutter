import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dialog that collects a new conversation title. Returns the entered string
/// via [Get.back], or null when cancelled.
///
/// Kept in the view layer (not the controller) so the controller stays free of
/// widget code and can be unit-tested without a widget binding.
class RenameConversationDialog extends StatefulWidget {
  final String initialTitle;

  const RenameConversationDialog({required this.initialTitle, super.key});

  @override
  State<RenameConversationDialog> createState() =>
      _RenameConversationDialogState();
}

class _RenameConversationDialogState extends State<RenameConversationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename conversation'),
      content: TextField(
        controller: _controller,
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
          onPressed: () => Get.back(result: _controller.text),
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
