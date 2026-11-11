import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';
import 'velora_alert.dart';
import 'velora_button.dart';
import 'velora_status.dart';

/// The visual state of one step in a [VeloraStepper].
enum VeloraStepState {
  /// Not reached yet.
  upcoming,

  /// The step the user is on.
  current,

  /// Finished.
  completed,

  /// Needs attention, e.g. it failed validation.
  error,

  /// Cannot be opened.
  disabled,
}

/// One step of a [VeloraStepper] or [VeloraWizard].
@immutable
class VeloraStep {
  /// Short step name.
  final String title;

  /// Optional supporting text under the title.
  final String? description;

  /// Marks the step as skippable; shown as "Optional".
  final bool optional;

  /// Overrides the state derived from the stepper's `currentStep`. Use it
  /// for [VeloraStepState.error] and [VeloraStepState.disabled].
  final VeloraStepState? state;

  /// Creates a step.
  const VeloraStep({
    required this.title,
    this.description,
    this.optional = false,
    this.state,
  });
}

/// Shows progress through a sequence of steps.
///
/// Presentation only. The caller owns [currentStep]; steps before it render
/// as completed and steps after it as upcoming, unless a step sets
/// [VeloraStep.state].
///
/// With [direction] horizontal, the stepper needs about 96 logical pixels
/// per step. In less space it collapses to a single "Step 2 of 5" line with
/// a progress bar, so it stays usable on small phones and at large text
/// sizes. Vertical never collapses.
///
/// Each step announces its position, title, and state to screen readers
/// ("Step 2 of 5, Address, current").
class VeloraStepper extends StatelessWidget {
  /// The steps, in order.
  final List<VeloraStep> steps;

  /// Index of the current step.
  final int currentStep;

  /// Called when a step is tapped. Disabled steps are never reported. When
  /// null, steps are not interactive.
  final ValueChanged<int>? onStepTapped;

  /// Layout direction.
  final Axis direction;

  /// Creates a stepper.
  VeloraStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepTapped,
    this.direction = Axis.horizontal,
  }) : assert(steps.isNotEmpty, 'VeloraStepper requires at least one step.'),
       assert(
         currentStep >= 0 && currentStep < steps.length,
         'VeloraStepper currentStep must identify a step.',
       );

  /// The state step [index] renders with.
  VeloraStepState stateOf(int index) {
    final explicit = steps[index].state;
    if (explicit != null) return explicit;
    if (index < currentStep) return VeloraStepState.completed;
    if (index == currentStep) return VeloraStepState.current;
    return VeloraStepState.upcoming;
  }

  String _semanticLabel(int index) {
    final step = steps[index];
    final parts = [
      'Step ${index + 1} of ${steps.length}',
      step.title,
      if (step.optional) 'optional',
      stateOf(index).name,
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.vertical) return _buildVertical(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final needed = steps.length * 96 * scale;
        if (constraints.maxWidth < needed) return _buildCollapsed(context);
        return _buildHorizontal(context);
      },
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final step = steps[currentStep];
    return Semantics(
      container: true,
      label: _semanticLabel(currentStep),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${currentStep + 1} of ${steps.length}',
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spacingXs),
          Text(step.title, style: textTheme.titleMedium),
          if (step.description != null) ...[
            SizedBox(height: tokens.spacingXs / 2),
            Text(
              step.description!,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: tokens.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusPill),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / steps.length,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontal(BuildContext context) {
    final tokens = context.veloraTokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _tappable(
              context,
              i,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: _connector(context, i, leading: true)),
                      _indicator(context, i),
                      Expanded(child: _connector(context, i, leading: false)),
                    ],
                  ),
                  SizedBox(height: tokens.spacingXs),
                  _labels(context, i, TextAlign.center),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVertical(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          _tappable(
            context,
            i,
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      _indicator(context, i),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            constraints: const BoxConstraints(minHeight: 16),
                            color: stateOf(i) == VeloraStepState.completed
                                ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: tokens.spacingSm),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: tokens.spacingXs,
                        bottom: tokens.spacingMd,
                      ),
                      child: _labels(context, i, TextAlign.start),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tappable(BuildContext context, int index, Widget child) {
    final tokens = context.veloraTokens;
    final onTapped = onStepTapped;
    final enabled =
        onTapped != null && stateOf(index) != VeloraStepState.disabled;
    return Semantics(
      container: true,
      label: _semanticLabel(index),
      button: enabled,
      enabled: stateOf(index) != VeloraStepState.disabled,
      onTap: enabled ? () => onTapped(index) : null,
      excludeSemantics: true,
      child: enabled
          ? InkWell(
              onTap: () => onTapped(index),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: child,
            )
          : child,
    );
  }

  Widget _connector(BuildContext context, int index, {required bool leading}) {
    final scheme = Theme.of(context).colorScheme;
    final hidden = leading ? index == 0 : index == steps.length - 1;
    // The line into a step is filled once the previous step is completed.
    final filledBy = leading ? index - 1 : index;
    final filled = !hidden && stateOf(filledBy) == VeloraStepState.completed;
    return Container(
      height: 2,
      color: hidden
          ? Colors.transparent
          : (filled ? scheme.primary : scheme.outlineVariant),
    );
  }

  Widget _indicator(BuildContext context, int index) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final state = stateOf(index);
    final (Color background, Color foreground, Color border) = switch (state) {
      VeloraStepState.completed || VeloraStepState.current => (
        scheme.primary,
        scheme.onPrimary,
        scheme.primary,
      ),
      VeloraStepState.error => (scheme.error, scheme.onError, scheme.error),
      VeloraStepState.upcoming => (
        Colors.transparent,
        scheme.onSurfaceVariant,
        scheme.outline,
      ),
      VeloraStepState.disabled => (
        Colors.transparent,
        scheme.onSurface.withValues(alpha: 0.38),
        scheme.outlineVariant,
      ),
    };
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : tokens.motionFast,
      width: 28,
      height: 28,
      margin: EdgeInsets.symmetric(horizontal: tokens.spacingXs),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
      ),
      child: switch (state) {
        VeloraStepState.completed => Icon(
          Icons.check,
          size: 16,
          color: foreground,
        ),
        VeloraStepState.error => Icon(
          Icons.priority_high,
          size: 16,
          color: foreground,
        ),
        _ => Text(
          '${index + 1}',
          // The number sits in a fixed 28px circle; do not let large text
          // settings push it out. The title beside it still scales.
          textScaler: TextScaler.noScaling,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: foreground),
        ),
      },
    );
  }

  Widget _labels(BuildContext context, int index, TextAlign align) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final step = steps[index];
    final state = stateOf(index);
    final titleColor = switch (state) {
      VeloraStepState.error => scheme.error,
      VeloraStepState.disabled => scheme.onSurface.withValues(alpha: 0.38),
      VeloraStepState.upcoming => scheme.onSurfaceVariant,
      _ => scheme.onSurface,
    };
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          step.title,
          textAlign: align,
          style: textTheme.labelLarge?.copyWith(color: titleColor),
        ),
        if (step.optional) Text('Optional', textAlign: align, style: muted),
        if (step.description != null)
          Text(step.description!, textAlign: align, style: muted),
      ],
    );
  }
}

/// A multi-step flow: a [VeloraStepper], the current step's content, and
/// Back / Continue / Submit actions.
///
/// The wizard holds no flow state. The caller owns [currentStep], validates
/// in [onNext], and persists or submits in [onSubmit]; the wizard only
/// reports what was pressed. It is not tied to any form or state-management
/// library.
///
/// **State is kept.** Every step that has been visited stays mounted (but
/// hidden), so text typed on step 1 is still there after going to step 3 and
/// back. Steps that were never visited are not built.
///
/// **Double submission is prevented.** If [onNext] or [onSubmit] returns a
/// `Future`, all actions are disabled and the primary button shows a spinner
/// until it completes. Set [busy] to do the same from outside.
///
/// **Focus.** After [currentStep] changes, focus moves to the start of the
/// new step, so the next Tab lands on its first field.
class VeloraWizard extends StatefulWidget {
  /// The steps, in order.
  final List<VeloraStep> steps;

  /// Index of the step being shown.
  final int currentStep;

  /// Builds the content of step `index`.
  final Widget Function(BuildContext context, int index) stepBuilder;

  /// Called when Continue is pressed. Validate here, then advance
  /// [currentStep]. May be async.
  final FutureOr<void> Function()? onNext;

  /// Called when Back is pressed.
  final VoidCallback? onBack;

  /// Called when the primary button is pressed on the last step. May be
  /// async.
  final FutureOr<void> Function()? onSubmit;

  /// Forwarded to [VeloraStepper.onStepTapped].
  final ValueChanged<int>? onStepTapped;

  /// Disables all actions and shows a spinner on the primary button.
  final bool busy;

  /// Whether the primary button is enabled.
  final bool canContinue;

  /// An error to show above the actions, e.g. a failed submission.
  final String? errorText;

  /// Label of the Back button.
  final String backLabel;

  /// Label of the primary button on every step but the last.
  final String nextLabel;

  /// Label of the primary button on the last step.
  final String submitLabel;

  /// Direction of the stepper.
  final Axis stepperDirection;

  /// Creates a wizard.
  VeloraWizard({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.stepBuilder,
    this.onNext,
    this.onBack,
    this.onSubmit,
    this.onStepTapped,
    this.busy = false,
    this.canContinue = true,
    this.errorText,
    this.backLabel = 'Back',
    this.nextLabel = 'Continue',
    this.submitLabel = 'Submit',
    this.stepperDirection = Axis.horizontal,
  }) : assert(steps.isNotEmpty, 'VeloraWizard requires at least one step.'),
       assert(
         currentStep >= 0 && currentStep < steps.length,
         'VeloraWizard currentStep must identify a step.',
       );

  @override
  State<VeloraWizard> createState() => _VeloraWizardState();
}

class _VeloraWizardState extends State<VeloraWizard> {
  final Set<int> _visited = {};
  final FocusNode _stepFocus = FocusNode(debugLabel: 'VeloraWizard step');
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _visited.add(widget.currentStep);
  }

  @override
  void didUpdateWidget(covariant VeloraWizard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.removeWhere((index) => index >= widget.steps.length);
    if (oldWidget.currentStep != widget.currentStep) {
      _visited.add(widget.currentStep);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _stepFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _stepFocus.dispose();
    super.dispose();
  }

  Future<void> _run(FutureOr<void> Function()? action) async {
    if (action == null || _pending) return;
    final result = action();
    if (result is! Future) return;
    setState(() => _pending = true);
    try {
      await result;
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final isFirst = widget.currentStep == 0;
    final isLast = widget.currentStep == widget.steps.length - 1;
    final busy = widget.busy || _pending;
    final primary = isLast ? widget.onSubmit : widget.onNext;
    final step = widget.steps[widget.currentStep];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        VeloraStepper(
          steps: widget.steps,
          currentStep: widget.currentStep,
          onStepTapped: busy ? null : widget.onStepTapped,
          direction: widget.stepperDirection,
        ),
        SizedBox(height: tokens.spacingLg),
        Focus(
          focusNode: _stepFocus,
          child: Semantics(
            container: true,
            label:
                'Step ${widget.currentStep + 1} of ${widget.steps.length}, '
                '${step.title}',
            child: IndexedStack(
              index: widget.currentStep,
              sizing: StackFit.loose,
              children: [
                for (var i = 0; i < widget.steps.length; i++)
                  _visited.contains(i)
                      ? KeyedSubtree(
                          key: ValueKey<int>(i),
                          child: Builder(
                            builder: (context) =>
                                widget.stepBuilder(context, i),
                          ),
                        )
                      : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          SizedBox(height: tokens.spacingMd),
          VeloraAlert(status: VeloraStatus.error, message: widget.errorText!),
        ],
        SizedBox(height: tokens.spacingLg),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: tokens.spacingSm,
          runSpacing: tokens.spacingSm,
          children: [
            if (!isFirst)
              VeloraButton(
                label: widget.backLabel,
                variant: VeloraButtonVariant.outline,
                onPressed: busy ? null : widget.onBack,
              )
            else
              const SizedBox.shrink(),
            VeloraButton(
              label: isLast ? widget.submitLabel : widget.nextLabel,
              loading: busy,
              onPressed: busy || !widget.canContinue || primary == null
                  ? null
                  : () => _run(primary),
            ),
          ],
        ),
      ],
    );
  }
}
