import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A pulsing placeholder block shown while real content loads.
///
/// It gently animates its opacity between two values (a "pulse", not a
/// gradient shimmer — cheaper and calmer) using [VeloraTokens.motionSlow] for
/// timing and the theme's surface colors for the fill, so skeletons match the
/// rest of the kit. The animation is automatically disabled when the platform
/// requests reduced motion (`MediaQuery.disableAnimations`), falling back to a
/// static block.
///
/// Use the default constructor for an arbitrary box, [VeloraSkeleton.circle]
/// for avatars, and [VeloraSkeleton.text] for a single text line.
class VeloraSkeleton extends StatefulWidget {
  /// The placeholder's width. Null lets it size to its parent's constraints.
  final double? width;

  /// The placeholder's height.
  final double height;

  /// The corner radius. Defaults to [VeloraTokens.radiusSm] when null.
  final double? radius;

  /// When true the placeholder is a circle of diameter [height] (ignoring
  /// [width]/[radius]). Set by [VeloraSkeleton.circle].
  final bool _circle;

  /// Creates a rectangular skeleton block.
  const VeloraSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius,
  }) : _circle = false;

  /// A circular skeleton (for avatars) of the given [diameter].
  const VeloraSkeleton.circle({super.key, required double diameter})
    : width = diameter,
      height = diameter,
      radius = null,
      _circle = true;

  /// A single skeleton text line. [width] defaults to a typical line width via
  /// the parent's constraints; set it for a specific fraction.
  const VeloraSkeleton.text({super.key, this.width, this.height = 12})
    : radius = null,
      _circle = false;

  @override
  State<VeloraSkeleton> createState() => _VeloraSkeletonState();
}

class _VeloraSkeletonState extends State<VeloraSkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Lazily create/tear down the controller so the reduced-motion path pays
    // nothing and never leaves a ticker running.
    if (reduceMotion) {
      _controller?.dispose();
      _controller = null;
    } else {
      _controller ??=
          AnimationController(vsync: this, duration: tokens.motionSlow)
            ..repeat(reverse: true);
    }

    final baseColor = scheme.surfaceContainerHighest;
    final borderRadius = BorderRadius.circular(
      widget._circle ? widget.height : (widget.radius ?? tokens.radiusSm),
    );

    Widget box(double opacity) => Opacity(
      opacity: opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: baseColor, borderRadius: borderRadius),
      ),
    );

    final controller = _controller;
    if (controller == null) return box(0.7);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) =>
          box(0.4 + 0.4 * controller.value), // 0.4 -> 0.8
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
