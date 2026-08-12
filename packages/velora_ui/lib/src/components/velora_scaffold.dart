import 'package:flutter/material.dart';

/// A convenience page scaffold that gives an app the Velora look in one
/// widget.
///
/// Wraps Material's [Scaffold] with an [AppBar] built from [title]
/// (rendered as `Text(title)`), [leading], and [actions] — the app bar's
/// flat surface color, title text style, and layout already come from the
/// active theme's `AppBarTheme` (set up by `buildVeloraTheme`), so this
/// widget only wires the content through rather than re-styling it. No
/// [AppBar] is built at all when [title], [leading], and [actions] are all
/// null, so a full-bleed screen doesn't pay for an empty bar. [body],
/// [bottomNavigationBar] (typically a [VeloraNavBar]), and
/// [floatingActionButton] are passed straight through to [Scaffold].
class VeloraScaffold extends StatelessWidget {
  /// The app bar's title. Rendered as `Text(title)`. When null (and
  /// [leading]/[actions] are also null), no app bar is shown.
  final String? title;

  /// Widgets shown at the end of the app bar (e.g. icon buttons).
  final List<Widget>? actions;

  /// A widget shown at the start of the app bar (e.g. a back button).
  final Widget? leading;

  /// The screen's main content.
  final Widget body;

  /// A widget shown at the bottom of the screen, typically a [VeloraNavBar].
  final Widget? bottomNavigationBar;

  /// An optional floating action button.
  final Widget? floatingActionButton;

  /// Creates a Velora page scaffold.
  const VeloraScaffold({
    super.key,
    this.title,
    this.actions,
    this.leading,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final showAppBar = title != null || leading != null || actions != null;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: title == null ? null : Text(title!),
              leading: leading,
              actions: actions,
            )
          : null,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
