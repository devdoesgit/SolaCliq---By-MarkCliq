import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';

/// The SolaCliq [ThemeData]: flat, square, rust red on warm paper.
///
/// Matches markcliq.com: Space Grotesk and Space Mono (bundled), square
/// corners, 1px rules, no shadows. Light only for now. Material widgets not
/// wrapped by `sola_ui` still pick up the tokens here.
abstract final class SolaTheme {
  /// The light theme.
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: SolaColors.accent,
      onPrimary: SolaColors.onAccent,
      primaryContainer: SolaColors.accentTint,
      onPrimaryContainer: SolaColors.ink,
      secondary: SolaColors.ink,
      onSecondary: SolaColors.surface,
      error: SolaColors.danger,
      onError: SolaColors.surface,
      errorContainer: SolaColors.dangerTint,
      onErrorContainer: SolaColors.danger,
      surface: SolaColors.surface,
      onSurface: SolaColors.ink,
      onSurfaceVariant: SolaColors.inkMuted,
      surfaceContainerLowest: SolaColors.surface,
      surfaceContainerLow: SolaColors.surface,
      surfaceContainer: SolaColors.surfaceSunken,
      surfaceContainerHigh: SolaColors.surfaceSunken,
      surfaceContainerHighest: SolaColors.surfaceSunken,
      outline: SolaColors.lineStrong,
      outlineVariant: SolaColors.line,
      shadow: Color(0x00000000),
      scrim: Color(0x66000000),
      surfaceTint: Color(0x00000000),
    );

    const square = RoundedRectangleBorder();

    return ThemeData(
      useMaterial3: true,
      fontFamily: solaSansFontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SolaColors.surface,
      canvasColor: SolaColors.surface,
      // Flat: tap feedback is a colour change, not a ripple.
      splashFactory: NoSplash.splashFactory,
      highlightColor: SolaColors.surfaceSunken,
      hoverColor: SolaColors.surfaceSunken,
      focusColor: const Color(0x00000000),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: TextTheme(
        displaySmall: SolaTextStyle.display.textStyle(),
        headlineMedium: SolaTextStyle.h1.textStyle(),
        titleLarge: SolaTextStyle.h2.textStyle(),
        titleMedium: SolaTextStyle.title.textStyle(),
        bodyLarge: SolaTextStyle.body.textStyle(),
        bodyMedium: SolaTextStyle.body.textStyle(),
        bodySmall: SolaTextStyle.bodySm.textStyle(color: SolaColors.inkMuted),
        labelLarge: SolaTextStyle.button.textStyle(),
        labelSmall: SolaTextStyle.label.textStyle(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SolaColors.surface,
        foregroundColor: SolaColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: const Color(0x00000000),
        centerTitle: false,
        titleTextStyle: SolaTextStyle.h2.textStyle(),
        shape: const Border(bottom: BorderSide(color: SolaColors.line)),
      ),
      dividerTheme: const DividerThemeData(
        color: SolaColors.line,
        thickness: SolaSize.hairline,
        space: SolaSize.hairline,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: SolaColors.surface,
        shape: RoundedRectangleBorder(side: BorderSide(color: SolaColors.line)),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: const DialogThemeData(
        elevation: 0,
        backgroundColor: SolaColors.surface,
        shape: RoundedRectangleBorder(side: BorderSide(color: SolaColors.ink)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: SolaColors.surface,
        shape: Border(top: BorderSide(color: SolaColors.ink)),
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        backgroundColor: SolaColors.ink,
        contentTextStyle: SolaTextStyle.body.textStyle(
          color: SolaColors.surface,
        ),
        shape: square,
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SolaColors.accent,
        linearTrackColor: SolaColors.surfaceSunken,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: SolaColors.ink,
        selectionColor: SolaColors.accentTint,
        selectionHandleColor: SolaColors.accent,
      ),
    );
  }
}
