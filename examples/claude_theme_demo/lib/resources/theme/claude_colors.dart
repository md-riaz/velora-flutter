import 'package:flutter/material.dart';

/// Claude brand color palette.
///
/// The primary orange-copper and surface hierarchy are hand-tuned to match
/// Anthropic's Claude product identity rather than generated via fromSeed,
/// giving us precise warm tones across both modes.
class ClaudeColors {
  // Primary brand — warm copper/orange
  static const Color primary = Color(0xFFD97757);
  static const Color primaryLight = Color(0xFFEBA98C);
  static const Color primaryDark = Color(0xFFB85A38);

  // Light mode surface stack
  static const Color bgLight = Color(0xFFFAFAF8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight = Color(0xFFF5F4F0);
  static const Color surfaceContainerHighLight = Color(0xFFEEEBE3);
  static const Color outlineLight = Color(0xFFBAB5AD);

  // Dark mode surface stack
  static const Color bgDark = Color(0xFF1C1B19);
  static const Color surfaceDark = Color(0xFF262523);
  static const Color surfaceContainerDark = Color(0xFF2E2D2A);
  static const Color surfaceContainerHighDark = Color(0xFF3A3835);
  static const Color outlineDark = Color(0xFF6B6760);

  // Semantic
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF1A0800);

  // Message bubbles (not in Material scheme)
  static const Color userBubbleLight = Color(0xFFEEEBE3);
  static const Color userBubbleDark = Color(0xFF3A3835);
  static const Color assistantBubbleLight = Colors.transparent;
  static const Color assistantBubbleDark = Colors.transparent;

  // Code blocks
  static const Color codeBlockLight = Color(0xFFF0EDE6);
  static const Color codeBlockDark = Color(0xFF1A1916);

  // Input area
  static const Color inputBgLight = Color(0xFFF0EDE6);
  static const Color inputBgDark = Color(0xFF2A2926);
}
