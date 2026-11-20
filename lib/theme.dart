import 'package:flutter/material.dart';

/// Monochrome palette that resolves from the currently selected brightness.
/// Light mode uses system greys on white; dark mode inverts to greys on near
/// black. Every colour stays strictly black-and-white.
class AppPalette {
  AppPalette._();

  static Brightness brightness = Brightness.light;
  static bool get isDark => brightness == Brightness.dark;

  static Color get background =>
      isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F7);
  static Color get surface =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFAFAFC);
  static Color get surfaceSunken =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEFF4);

  static Color get ink =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1D1D1F);
  static Color get inkSoft =>
      isDark ? const Color(0xFFE5E5EA) : const Color(0xFF3A3A3C);
  static Color get muted =>
      isDark ? const Color(0xFF98989D) : const Color(0xFF86868B);
  static Color get line =>
      isDark ? const Color(0xFF38383A) : const Color(0xFFE8E8ED);
  static Color get lineStrong =>
      isDark ? const Color(0xFF48484A) : const Color(0xFFD2D2D7);

  static Color get fresh => ink;
  static Color get soon =>
      isDark ? const Color(0xFFAEAEB2) : const Color(0xFF6E6E73);
  static Color get expired =>
      isDark ? const Color(0xFF636366) : const Color(0xFFA1A1A6);

  /// Foreground for text/icons placed on an [ink] filled surface.
  static Color get onInk =>
      isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  static Color get glass => isDark
      ? const Color(0xB31C1C1E)
      : const Color(0xCFFFFFFF);
  static Color get scrim => isDark
      ? const Color(0xCC000000)
      : const Color(0x4D1D1D1F);
  static Color get shadow => isDark
      ? const Color(0x40FFFFFF)
      : const Color(0x121D1D1F);

  static BoxDecoration card({Color? fill, double radius = 26}) => BoxDecoration(
        color: fill ?? surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33FFFFFF) : const Color(0x081D1D1F),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: isDark ? const Color(0x1FFFFFFF) : const Color(0x0C1D1D1F),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );

  /// A quiet, hairline-bordered surface used for inputs and subtle controls.
  static BoxDecoration field({Color? fill, double radius = 14}) => BoxDecoration(
        color: fill ?? surfaceSunken,
        borderRadius: BorderRadius.circular(radius),
      );
}

/// Refined, system-like typography: tight tracking on large sizes, generous
/// line height on body copy, understated all-caps overlines.
class AppText {
  const AppText._();

  static TextStyle get display => TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.w700,
        letterSpacing: -2.6,
        height: 1.04,
        color: AppPalette.ink,
      );

  static TextStyle get heading => TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        height: 1.15,
        color: AppPalette.ink,
      );

  static TextStyle get title => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppPalette.ink,
      );

  static TextStyle get label => TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppPalette.muted,
      );

  static TextStyle get value => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppPalette.ink,
      );

  static TextStyle get bigNumber => TextStyle(
        fontSize: 46,
        fontWeight: FontWeight.w700,
        letterSpacing: -2.2,
        height: 1,
        color: AppPalette.ink,
      );

  static TextStyle get body => TextStyle(
        fontSize: 13.5,
        height: 1.5,
        color: AppPalette.inkSoft,
      );

  static TextStyle get bodyMuted => TextStyle(
        fontSize: 12.5,
        height: 1.5,
        color: AppPalette.muted,
      );

  static TextStyle get chip => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppPalette.muted,
      );

  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle get mono => TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: AppPalette.ink,
      );
}

ThemeData buildTheme() {
  final scheme = ColorScheme(
    brightness: AppPalette.brightness,
    primary: AppPalette.ink,
    onPrimary: AppPalette.onInk,
    secondary: AppPalette.inkSoft,
    onSecondary: AppPalette.onInk,
    error: AppPalette.expired,
    onError: AppPalette.onInk,
    surface: AppPalette.surface,
    onSurface: AppPalette.ink,
    surfaceContainerHighest: AppPalette.surfaceSunken,
    onSurfaceVariant: AppPalette.muted,
    outline: AppPalette.lineStrong,
    outlineVariant: AppPalette.line,
    shadow: AppPalette.shadow,
    scrim: AppPalette.scrim,
    inverseSurface: AppPalette.ink,
    onInverseSurface: AppPalette.onInk,
    inversePrimary: AppPalette.surface,
    primaryFixed: AppPalette.surfaceSunken,
    onPrimaryFixed: AppPalette.ink,
    primaryFixedDim: AppPalette.muted,
    onPrimaryFixedVariant: AppPalette.ink,
    secondaryFixed: AppPalette.surfaceSunken,
    onSecondaryFixed: AppPalette.ink,
    secondaryFixedDim: AppPalette.muted,
    onSecondaryFixedVariant: AppPalette.ink,
    tertiaryFixed: AppPalette.surfaceSunken,
    onTertiaryFixed: AppPalette.ink,
    tertiaryFixedDim: AppPalette.muted,
    onTertiaryFixedVariant: AppPalette.ink,
    surfaceDim: AppPalette.background,
    surfaceBright: AppPalette.surface,
    surfaceContainerLowest: AppPalette.surface,
    surfaceContainerLow: AppPalette.surfaceAlt,
    surfaceContainer: AppPalette.surfaceAlt,
    surfaceContainerHigh: AppPalette.surfaceSunken,
    surfaceTint: AppPalette.ink,
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide.none,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppPalette.background,
    textTheme: TextTheme(
      displayLarge: AppText.display,
      headlineSmall: AppText.heading,
      titleMedium: AppText.title,
      bodyMedium: AppText.body,
      bodySmall: AppText.bodyMuted,
      labelSmall: AppText.label,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.surfaceSunken,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: TextStyle(color: AppPalette.muted, fontSize: 13.5),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppPalette.ink, width: 1.4),
      ),
      errorBorder: inputBorder,
      focusedErrorBorder: inputBorder,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppPalette.ink,
        foregroundColor: AppPalette.onInk,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppPalette.muted,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    iconTheme: IconThemeData(color: AppPalette.muted, size: 20),
    dividerTheme: DividerThemeData(
      color: AppPalette.line,
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: AppPalette.surfaceSunken,
      headerForegroundColor: AppPalette.ink,
      dayForegroundColor: WidgetStateProperty.all(AppPalette.ink),
      todayForegroundColor: WidgetStateProperty.all(AppPalette.ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(color: AppPalette.onInk, fontSize: 11),
    ),
  );
}
