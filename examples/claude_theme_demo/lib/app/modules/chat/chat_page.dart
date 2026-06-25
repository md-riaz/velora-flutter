import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../../resources/theme/claude_colors.dart';
import '../../../resources/theme/claude_extensions.dart';
import 'chat_controller.dart';
import 'chat_message.dart';

class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<ClaudeTokens>()!;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: _ChatAppBar(scheme: scheme),
      body: Column(
        children: [
          // Send error banner
          Obx(() {
            final err = controller.error.value;
            if (err.isEmpty) return const SizedBox.shrink();
            return Container(
              color: scheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: scheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      err,
                      style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: scheme.onErrorContainer),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: controller.clearError,
                  ),
                ],
              ),
            );
          }),

          Expanded(
            child: Obx(() {
              if (controller.loading.value && controller.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }
              final msgs = controller.messages;
              if (msgs.isEmpty) {
                return _WelcomePrompts(tokens: tokens);
              }

              // Total item count: optional load-earlier header + messages + optional typing indicator
              final hasEarlier = controller.hasEarlier.value;
              final isTyping = controller.isTyping.value;
              final headerCount = hasEarlier ? 1 : 0;
              final typingCount = isTyping ? 1 : 0;
              final totalItems = headerCount + msgs.length + typingCount;

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  // Load-earlier header
                  if (hasEarlier && index == 0) {
                    return _LoadEarlierButton(controller: controller);
                  }

                  final msgIndex = index - headerCount;

                  // Typing indicator at the end
                  if (msgIndex == msgs.length) {
                    return _TypingIndicator(tokens: tokens);
                  }

                  return _MessageBubble(
                    message: msgs[msgIndex],
                    tokens: tokens,
                  );
                },
              );
            }),
          ),
          _InputBar(
            controller: controller,
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Load-earlier header
// ---------------------------------------------------------------------------

class _LoadEarlierButton extends StatelessWidget {
  final ChatController controller;
  const _LoadEarlierButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Obx(() {
          if (controller.loadingEarlier.value) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
            );
          }
          return TextButton.icon(
            onPressed: controller.loadEarlier,
            icon: Icon(Icons.keyboard_arrow_up, size: 18, color: scheme.onSurfaceVariant),
            label: Text(
              'Load earlier messages',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            style: TextButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ColorScheme scheme;
  const _ChatAppBar({required this.scheme});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.find<ChatController>();

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Velora.nav.back(),
      ),
      title: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.conversation.value.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: ClaudeColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'claude-opus-4',
                  style: textTheme.labelSmall?.copyWith(
                    color: ClaudeColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          )),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () => _showMoreMenu(context, controller),
        ),
      ],
    );
  }

  void _showMoreMenu(BuildContext context, ChatController controller) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Obx(() {
          final isStarred = controller.conversation.value.isStarred;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  controller.conversation.value.title,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              _MenuAction(
                icon: Icons.drive_file_rename_outline,
                label: 'Rename',
                onTap: () {
                  Navigator.pop(context);
                  controller.renameConversation();
                },
              ),
              _MenuAction(
                icon: isStarred ? Icons.star : Icons.star_border,
                label: isStarred ? 'Remove star' : 'Star conversation',
                onTap: () {
                  Navigator.pop(context);
                  controller.toggleStar();
                },
              ),
              _MenuAction(
                icon: Icons.delete_sweep_outlined,
                label: 'Clear history',
                onTap: () {
                  Navigator.pop(context);
                  controller.clearHistory();
                },
              ),
              _MenuAction(
                icon: Icons.delete_outline,
                label: 'Delete conversation',
                color: scheme.error,
                onTap: () {
                  Navigator.pop(context);
                  controller.deleteConversation();
                },
              ),
              const SizedBox(height: 8),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.onSurface;

    return ListTile(
      leading: Icon(icon, size: 22, color: effectiveColor),
      title: Text(
        label,
        style: TextStyle(color: effectiveColor, fontSize: 15),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      dense: true,
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubbles
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ClaudeTokens tokens;

  const _MessageBubble({required this.message, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return message.isUser
        ? _UserMessage(message: message, tokens: tokens)
        : _AssistantMessage(message: message, tokens: tokens);
  }
}

class _UserMessage extends StatelessWidget {
  final ChatMessage message;
  final ClaudeTokens tokens;

  const _UserMessage({required this.message, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        margin: const EdgeInsets.only(left: 56, right: 16, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.userBubble,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          message.content,
          style: textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  final ChatMessage message;
  final ClaudeTokens tokens;

  const _AssistantMessage({required this.message, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 48, top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: tokens.avatarBackground,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Text(
                'C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _RichMessageContent(
              content: message.content,
              textTheme: textTheme,
              scheme: scheme,
              tokens: tokens,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rich message content (text + fenced code blocks)
// ---------------------------------------------------------------------------

class _RichMessageContent extends StatelessWidget {
  final String content;
  final TextTheme textTheme;
  final ColorScheme scheme;
  final ClaudeTokens tokens;

  const _RichMessageContent({
    required this.content,
    required this.textTheme,
    required this.scheme,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final parts = _splitCodeBlocks(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) {
        if (part.isCode) {
          return _CodeBlock(code: part.text, tokens: tokens, textTheme: textTheme);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(part.text, style: textTheme.bodyMedium),
        );
      }).toList(),
    );
  }

  static List<_ContentPart> _splitCodeBlocks(String text) {
    final result = <_ContentPart>[];
    final regex = RegExp(r'```(?:\w+)?\r?\n([\s\S]*?)```', multiLine: true);
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        result.add(_ContentPart(text.substring(lastEnd, match.start).trim(), false));
      }
      result.add(_ContentPart(match.group(1) ?? '', true));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      final remaining = text.substring(lastEnd).trim();
      if (remaining.isNotEmpty) result.add(_ContentPart(remaining, false));
    }
    return result.isEmpty ? [_ContentPart(text, false)] : result;
  }
}

class _ContentPart {
  final String text;
  final bool isCode;
  _ContentPart(this.text, this.isCode);
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final ClaudeTokens tokens;
  final TextTheme textTheme;

  const _CodeBlock({
    required this.code,
    required this.tokens,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.codeBlock,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code.trim(),
          style: textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing indicator
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatefulWidget {
  final ClaudeTokens tokens;
  const _TypingIndicator({required this.tokens});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.tokens.avatarBackground,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Text(
                'C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, child) => Row(
              children: List.generate(3, (i) {
                final delay = i * 0.3;
                final t = ((_anim.value - delay) % 1.0).clamp(0.0, 1.0);
                final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: ClaudeColors.primary.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome prompts (empty state)
// ---------------------------------------------------------------------------

class _WelcomePrompts extends StatelessWidget {
  final ClaudeTokens tokens;
  const _WelcomePrompts({required this.tokens});

  static const _prompts = [
    ('Explain a concept', Icons.lightbulb_outline),
    ('Write some code', Icons.code),
    ('Analyse data', Icons.bar_chart_outlined),
    ('Help me plan', Icons.checklist_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.find<ChatController>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ClaudeColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  'C',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'What can I help with?',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _prompts.map((p) {
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    controller.inputController.text = p.$1;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(p.$2, size: 16, color: ClaudeColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          p.$1,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input bar
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  final ChatController controller;
  final ClaudeTokens tokens;

  const _InputBar({required this.controller, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Use paddingOf (safe-area inset) not viewInsetsOf (keyboard height).
    // Scaffold's resizeToAvoidBottomInset already shrinks the view for the
    // keyboard, so adding viewInsets here would double-count it and push
    // the bar too high. paddingOf gives the iOS home-indicator gap when the
    // keyboard is closed and collapses to zero when it's open.
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() => VeloraAttachmentStrip(
              attachments: controller.attachments,
              onPickTap: () => controller.showAttachmentPicker(),
              onRemove: controller.removeAttachment,
              onRetry: controller.retryAttachment,
            )),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(color: scheme.outlineVariant, width: 0.5),
            ),
          ),
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: tokens.inputBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: scheme.onSurfaceVariant,
                        ),
                        iconSize: 22,
                        onPressed: () => controller.showAttachmentPicker(),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller.inputController,
                          maxLines: 5,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => controller.sendMessage(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            hintText: 'Message Claude…',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 10),
                            filled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                final isTyping = controller.isTyping.value;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isTyping
                        ? scheme.surfaceContainerHighest
                        : ClaudeColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: isTyping
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: controller.sendMessage,
                        ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
