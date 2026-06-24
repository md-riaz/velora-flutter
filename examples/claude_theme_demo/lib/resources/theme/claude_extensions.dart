import 'package:flutter/material.dart';

import 'claude_colors.dart';

/// Custom theme tokens for Claude-specific UI surfaces that don't map
/// to Material's standard [ColorScheme] (message bubbles, input bar, code blocks).
///
/// Access via [Theme.of(context).extension<ClaudeTokens>()!]
class ClaudeTokens extends ThemeExtension<ClaudeTokens> {
  final Color userBubble;
  final Color assistantBubble;
  final Color inputBackground;
  final Color codeBlock;
  final Color avatarBackground;

  const ClaudeTokens({
    required this.userBubble,
    required this.assistantBubble,
    required this.inputBackground,
    required this.codeBlock,
    required this.avatarBackground,
  });

  static const light = ClaudeTokens(
    userBubble: ClaudeColors.userBubbleLight,
    assistantBubble: ClaudeColors.assistantBubbleLight,
    inputBackground: ClaudeColors.inputBgLight,
    codeBlock: ClaudeColors.codeBlockLight,
    avatarBackground: ClaudeColors.primary,
  );

  static const dark = ClaudeTokens(
    userBubble: ClaudeColors.userBubbleDark,
    assistantBubble: ClaudeColors.assistantBubbleDark,
    inputBackground: ClaudeColors.inputBgDark,
    codeBlock: ClaudeColors.codeBlockDark,
    avatarBackground: ClaudeColors.primaryDark,
  );

  @override
  ClaudeTokens copyWith({
    Color? userBubble,
    Color? assistantBubble,
    Color? inputBackground,
    Color? codeBlock,
    Color? avatarBackground,
  }) {
    return ClaudeTokens(
      userBubble: userBubble ?? this.userBubble,
      assistantBubble: assistantBubble ?? this.assistantBubble,
      inputBackground: inputBackground ?? this.inputBackground,
      codeBlock: codeBlock ?? this.codeBlock,
      avatarBackground: avatarBackground ?? this.avatarBackground,
    );
  }

  @override
  ClaudeTokens lerp(ClaudeTokens? other, double t) {
    if (other is! ClaudeTokens) return this;
    return ClaudeTokens(
      userBubble: Color.lerp(userBubble, other.userBubble, t)!,
      assistantBubble: Color.lerp(assistantBubble, other.assistantBubble, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      codeBlock: Color.lerp(codeBlock, other.codeBlock, t)!,
      avatarBackground: Color.lerp(avatarBackground, other.avatarBackground, t)!,
    );
  }
}
