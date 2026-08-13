import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A pill segmented control for switching between views *within* a screen
/// (e.g. "Day / Week / Month") — not a top-level nav surface; see
/// [VeloraNavBar]/[VeloraNavRail] for that.
///
/// Controlled: pass [selectedIndex] and [onChanged]. Equal-width [tabs]
/// segments sit on a rounded `surfaceContainerHighest` track; the selected
/// segment is a `primary` pill (with an `onPrimary` label) that slides
/// between positions using [VeloraTokens.motionNormal], the same timing the
/// rest of the kit uses for its transitions.
///
/// [tabs] must not be empty.
class VeloraTabs extends StatelessWidget {
  /// The segment labels, left to right.
  final List<String> tabs;

  /// The index of the currently-selected segment.
  final int selectedIndex;

  /// Called with a segment's index when it's tapped.
  final ValueChanged<int> onChanged;

  /// Creates a Velora segmented tab control.
  ///
  /// Not a `const` constructor: [tabs] is asserted non-empty here, and that
  /// assertion can only be checked once the (necessarily non-constant)
  /// [tabs] value is known.
  VeloraTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  }) : assert(tabs.isNotEmpty, 'VeloraTabs requires at least one tab.');

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final trackRadius = BorderRadius.circular(tokens.radiusPill);

    return Container(
      height: 40,
      padding: EdgeInsets.all(tokens.spacingXs / 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: trackRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / tabs.length;

          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: tokens.motionNormal,
                curve: Curves.easeOut,
                top: 0,
                bottom: 0,
                start: segmentWidth * selectedIndex,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(tokens.radiusPill),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: Semantics(
                        selected: i == selectedIndex,
                        child: InkWell(
                          onTap: () => onChanged(i),
                          borderRadius: BorderRadius.circular(
                            tokens.radiusPill,
                          ),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: tokens.motionNormal,
                              curve: Curves.easeOut,
                              style:
                                  (textTheme.labelMedium ?? const TextStyle())
                                      .copyWith(
                                        color: i == selectedIndex
                                            ? scheme.onPrimary
                                            : scheme.onSurfaceVariant,
                                      ),
                              child: Text(
                                tabs[i],
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
