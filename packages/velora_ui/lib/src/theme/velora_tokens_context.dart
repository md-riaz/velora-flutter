import 'package:flutter/material.dart';

import '../tokens/velora_tokens.dart';

/// Convenient access to [VeloraTokens] from any [BuildContext] under a
/// Velora theme.
extension VeloraTokensContext on BuildContext {
  /// The [VeloraTokens] attached to the nearest [Theme] above this context.
  ///
  /// Equivalent to `Theme.of(context).extension<VeloraTokens>()!`, but with
  /// a clear error if it's missing instead of a bare null-check crash — this
  /// throws with a message telling you to build your `ThemeData` with
  /// `buildVeloraTheme(...)` or `VeloraTheme.light()`/`.dark()` (which both
  /// attach [VeloraTokens] via `ThemeData.extensions`) rather than a plain
  /// `ThemeData(...)` that never registered them.
  VeloraTokens get veloraTokens {
    final tokens = Theme.of(this).extension<VeloraTokens>();
    assert(
      tokens != null,
      'context.veloraTokens was read but no VeloraTokens ThemeExtension is '
      'registered on the current Theme. Build your ThemeData with '
      'buildVeloraTheme(...) or VeloraTheme.light()/.dark() from '
      'package:velora_ui, or add VeloraTokens.light/.dark to a custom '
      "ThemeData's extensions: [...] list yourself.",
    );
    if (tokens == null) {
      throw StateError(
        'context.veloraTokens was read but no VeloraTokens ThemeExtension is '
        'registered on the current Theme. Build your ThemeData with '
        'buildVeloraTheme(...) or VeloraTheme.light()/.dark() from '
        'package:velora_ui, or add VeloraTokens.light/.dark to a custom '
        "ThemeData's extensions: [...] list yourself.",
      );
    }
    return tokens;
  }
}
