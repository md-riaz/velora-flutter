import 'package:flutter/material.dart';

/// A [FilledButton] that shows a loading spinner when [loading] is true,
/// disabling the press handler during the async operation.
///
/// Usage:
/// ```dart
/// Obx(() => VeloraLoadingButton(
///   loading: controller.loading.value,
///   onPressed: controller.submit,
///   child: const Text('Save'),
/// ))
/// ```
class VeloraLoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? loadingChild;
  final ButtonStyle? style;

  const VeloraLoadingButton({
    required this.onPressed,
    required this.child,
    this.loading = false,
    this.loadingChild,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      style: style,
      onPressed: loading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: loading
            ? loadingChild ??
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
                  ),
                )
            : child,
      ),
    );
  }
}

/// Outlined variant of [VeloraLoadingButton].
class VeloraLoadingOutlinedButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? loadingChild;
  final ButtonStyle? style;

  const VeloraLoadingOutlinedButton({
    required this.onPressed,
    required this.child,
    this.loading = false,
    this.loadingChild,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: style,
      onPressed: loading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: loading
            ? loadingChild ??
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
                )
            : child,
      ),
    );
  }
}
