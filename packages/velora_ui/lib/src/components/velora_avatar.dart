import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A circular avatar — a photo, initials derived from a name, or a fallback
/// person icon, in that order of preference.
///
/// Pass [image] for a photo avatar; when it's null, or when it fails to load
/// (a broken URL, an offline device), the first 1-2 letters of [name] are
/// shown as initials on a tinted background instead. When both [image] and
/// [name] are null, a generic person icon is shown. The circle's diameter is
/// controlled by [size]; its shape comes from [VeloraTokens.radiusPill]
/// (large enough that any square box clips to a perfect circle), the same
/// pattern [VeloraChip] and [VeloraBadge] use for their pill shapes.
class VeloraAvatar extends StatelessWidget {
  /// The avatar's photo. When null — or when it fails to load — falls back
  /// to initials (or the icon, if [name] is also null).
  final ImageProvider? image;

  /// The name used to derive initials when there's no [image] to show. Null
  /// falls back to a generic person icon.
  final String? name;

  /// The circle's diameter, in logical pixels. Defaults to 40.
  final double size;

  /// The background color behind initials/icon. Defaults to the theme's
  /// `primaryContainer`.
  final Color? backgroundColor;

  /// The color of the initials text / fallback icon. Defaults to the
  /// theme's `onPrimaryContainer`.
  final Color? foregroundColor;

  /// Creates a Velora avatar.
  const VeloraAvatar({
    super.key,
    this.image,
    this.name,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// The 1-2 letter uppercase initials derived from [name] (e.g. "Ada
  /// Lovelace" -> "AL", "Ada" -> "A"), or null when [name] is null or blank.
  String? get _initials {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final background = backgroundColor ?? scheme.primaryContainer;
    final foreground = foregroundColor ?? scheme.onPrimaryContainer;

    Widget fallback() {
      final initials = _initials;
      return ColoredBox(
        color: background,
        child: Center(
          child: initials != null
              ? Text(
                  initials,
                  style: TextStyle(
                    color: foreground,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Icon(Icons.person, size: size * 0.55, color: foreground),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusPill),
      child: SizedBox(
        width: size,
        height: size,
        child: image == null
            ? fallback()
            : Image(
                image: image!,
                fit: BoxFit.cover,
                // A broken image (bad URL, offline device, corrupt bytes)
                // falls back to the same initials/icon treatment rather
                // than a jagged error glyph.
                errorBuilder: (context, error, stackTrace) => fallback(),
              ),
      ),
    );
  }
}
