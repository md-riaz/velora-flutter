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

  /// A single skeleton text line. [width] is an explicit width in logical
  /// pixels (passed straight to the underlying box); leave it null to size to
  /// the parent's constraints.
  const VeloraSkeleton.text({super.key, this.width, this.height = 12})
    : radius = null,
      _circle = false;

  @override
  State<VeloraSkeleton> createState() => _VeloraSkeletonState();
}

class _VeloraSkeletonState extends State<VeloraSkeleton>
    with SingleTickerProviderStateMixin {
  // One controller for the whole state lifetime — SingleTickerProviderStateMixin
  // only permits a single ticker to ever be created, so we never dispose and
  // recreate it. Reduced-motion is handled by stopping/restarting this one
  // controller (in didChangeDependencies), not by tearing it down.
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs on first build and whenever an inherited dependency changes —
    // including MediaQuery, so a live reduced-motion toggle lands here.
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _controller.duration = context.veloraTokens.motionSlow;
    if (reduceMotion) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

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

    if (reduceMotion) return box(0.7);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          box(0.4 + 0.4 * _controller.value), // 0.4 -> 0.8
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
