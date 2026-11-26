import 'package:flutter/material.dart';

import '../tokens/velora_tokens.dart';
import '../components/velora_status.dart';

@immutable
class ThemePreset {
  final String name;
  final Color seedColor;
  final double radius;
  final String? fontFamily;
  final DesignTokens? lightTokens;
  final DesignTokens? darkTokens;
  const ThemePreset({
    required this.name,
    required this.seedColor,
    this.radius = 8,
    this.fontFamily,
    this.lightTokens,
    this.darkTokens,
  });
  ThemePreset copyWith({
    String? name,
    Color? seedColor,
    double? radius,
    String? fontFamily,
    DesignTokens? lightTokens,
    DesignTokens? darkTokens,
  }) => ThemePreset(
    name: name ?? this.name,
    seedColor: seedColor ?? this.seedColor,
    radius: radius ?? this.radius,
    fontFamily: fontFamily ?? this.fontFamily,
    lightTokens: lightTokens ?? this.lightTokens,
    darkTokens: darkTokens ?? this.darkTokens,
  );
  static const aurora = ThemePreset(
    name: 'aurora',
    seedColor: Color(0xFF5B4FE6),
  );
  static const meadow = ThemePreset(
    name: 'meadow',
    seedColor: Color(0xFF1E8A6E),
  );
  static const neutral = ThemePreset(
    name: 'neutral',
    seedColor: Color(0xFF71717A),
    radius: 4,
  );
  static const corporate = ThemePreset(
    name: 'corporate',
    seedColor: Color(0xFF2563EB),
    radius: 6,
  );
  ThemeData light({
    ColorScheme? colorScheme,
    Color? seedColor,
    VisualDensity? visualDensity,
    TextTheme? textTheme,
    DesignTokens? tokens,
    StatusColors? statusColors,
    String? fontFamily,
    Iterable<ThemeExtension>? extensions,
  }) => _build(
    Brightness.light,
    colorScheme,
    seedColor,
    visualDensity,
    textTheme,
    tokens,
    statusColors,
    fontFamily,
    extensions,
  );
  ThemeData dark({
    ColorScheme? colorScheme,
    Color? seedColor,
    VisualDensity? visualDensity,
    TextTheme? textTheme,
    DesignTokens? tokens,
    StatusColors? statusColors,
    String? fontFamily,
    Iterable<ThemeExtension>? extensions,
  }) => _build(
    Brightness.dark,
    colorScheme,
    seedColor,
    visualDensity,
    textTheme,
    tokens,
    statusColors,
    fontFamily,
    extensions,
  );
  ThemeData _build(
    Brightness brightness,
    ColorScheme? overrideScheme,
    Color? overrideSeed,
    VisualDensity? visualDensity,
    TextTheme? overrideTextTheme,
    DesignTokens? overrideTokens,
    StatusColors? statusColors,
    String? overrideFontFamily,
    Iterable<ThemeExtension>? extensions,
  ) {
    final colorScheme =
        overrideScheme ??
        ColorScheme.fromSeed(
          seedColor: overrideSeed ?? seedColor,
          brightness: brightness,
          dynamicSchemeVariant: identical(this, neutral) && overrideSeed == null
              ? DynamicSchemeVariant.monochrome
              : DynamicSchemeVariant.tonalSpot,
        );
    final tokens =
        overrideTokens ??
        (colorScheme.brightness == Brightness.dark
            ? darkTokens
            : lightTokens) ??
        (colorScheme.brightness == Brightness.dark
                ? DesignTokens.dark
                : DesignTokens.light)
            .copyWith(
              radiusMd: radius,
              radiusLg: radius * 2,
              spacingMd: identical(this, corporate) ? 12 : 16,
            );
    final effectiveFontFamily = overrideFontFamily ?? fontFamily;
    final textTheme =
        overrideTextTheme ??
        ThemeData(
          colorScheme: colorScheme,
          fontFamily: effectiveFontFamily,
        ).textTheme;
    final radiusMd = BorderRadius.circular(tokens.radiusMd);
    final radiusLg = BorderRadius.circular(tokens.radiusLg);

    // Shared button geometry: flat (no Material elevation), token-rounded,
    // comfortably tall, wearing Velora's semi-bold tracked label.
    ButtonStyle buttonStyle() => ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
    );

    final stateColor = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled))
        return colorScheme.onSurface.withValues(alpha: 0.38);
      return states.contains(WidgetState.selected)
          ? colorScheme.primary
          : colorScheme.onSurfaceVariant;
    });
    final mergedExtensions = <ThemeExtension>[
      tokens,
      statusColors ?? StatusColors.fromScheme(colorScheme, tokens),
      ...?extensions,
    ];

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      fontFamily: effectiveFontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: visualDensity ?? VisualDensity.adaptivePlatformDensity,
      extensions: mergedExtensions,

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return states.contains(WidgetState.selected)
                ? colorScheme.surface
                : colorScheme.onSurface.withValues(alpha: 0.38);
          }
          return states.contains(WidgetState.selected)
              ? colorScheme.onPrimary
              : colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return states.contains(WidgetState.selected)
                ? colorScheme.onSurface.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.12);
          }
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return states.contains(WidgetState.disabled)
              ? colorScheme.onSurface.withValues(alpha: 0.12)
              : colorScheme.outline;
        }),
      ),
      checkboxTheme: CheckboxThemeData(fillColor: stateColor),
      radioTheme: RadioThemeData(fillColor: stateColor),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
      ),
      listTileTheme: ListTileThemeData(
        dense: identical(this, corporate),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.primary),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(foregroundColor: stateColor),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHighest,
        ),
        dataRowColor: WidgetStatePropertyAll(colorScheme.surface),
      ),

      // Flat, surface-colored app bar with the bold title style.
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: tokens.elevation1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),

      // Buttons: flat, token-rounded, tracked labels.
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle()),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttonStyle().copyWith(
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: buttonStyle().copyWith(
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: tokens.spacingMd),
          ),
        ),
      ),

      // Cards: flat with a hairline outline and a large token radius.
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radiusLg,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      // Inputs: softly filled, token-rounded, with a 2px primary focus ring.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spacingMd,
          vertical: tokens.spacingSm + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: TextStyle(color: colorScheme.primary),
      ),

      // Chips: fully-pill, hairline outline.
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: colorScheme.outlineVariant),
        labelStyle: textTheme.labelMedium,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacingSm,
          vertical: tokens.spacingXs,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: tokens.spacingMd,
      ),

      dialogTheme: DialogThemeData(
        elevation: tokens.elevation3,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
      ),

      // Tooltips: inverse-surface pill, small token radius/padding.
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacingSm,
          vertical: tokens.spacingXs,
        ),
      ),

      // Bottom sheets: surface-colored, rounded top corners at the large
      // token radius. `showDragHandle` is left to the bottom sheet's helper
      // rather than forced here, since a caller may opt out per sheet.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.radiusLg),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
