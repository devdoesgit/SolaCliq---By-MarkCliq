import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';

/// The SolaCliq [ThemeData], iOS v2: warm cream, white cards with soft
/// shadows, one sun-yellow accent. Screens draw with `sola_ui` widgets;
/// this theme makes any Material widget they don't wrap match.
abstract final class SolaTheme {
  /// The light theme.
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: SolaColors.brown,
      onPrimary: SolaColors.cream,
      primaryContainer: SolaColors.sun,
      onPrimaryContainer: SolaColors.ink,
      secondary: SolaColors.sun,
      onSecondary: SolaColors.ink,
      error: SolaColors.danger,
      onError: SolaColors.surface,
      errorContainer: SolaColors.dangerTint,
      onErrorContainer: SolaColors.danger,
      surface: SolaColors.cream,
      onSurface: SolaColors.ink,
      onSurfaceVariant: SolaColors.muted,
      surfaceContainerLowest: SolaColors.surface,
      surfaceContainerLow: SolaColors.cream,
      surfaceContainer: SolaColors.cream,
      surfaceContainerHigh: SolaColors.creamDeep,
      surfaceContainerHighest: SolaColors.tan,
      outline: SolaColors.dashed,
      outlineVariant: SolaColors.line,
      shadow: SolaColors.brown,
      scrim: Color(0x591E1612),
      surfaceTint: Color(0x00000000),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: solaSansFontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SolaColors.cream,
      canvasColor: SolaColors.cream,
      splashFactory: NoSplash.splashFactory,
      highlightColor: SolaColors.tan,
      hoverColor: SolaColors.tan,
      focusColor: const Color(0x00000000),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: TextTheme(
        headlineMedium: SolaTextStyle.title.textStyle(),
        titleLarge: SolaTextStyle.section.textStyle(),
        titleMedium: SolaTextStyle.rowTitle.textStyle(),
        bodyLarge: SolaTextStyle.bodyLg.textStyle(),
        bodyMedium: SolaTextStyle.body.textStyle(),
        bodySmall: SolaTextStyle.meta.textStyle(color: SolaColors.muted),
        labelLarge: SolaTextStyle.button.textStyle(),
        labelSmall: SolaTextStyle.eyebrow.textStyle(),
      ),
      dividerTheme: const DividerThemeData(
        color: SolaColors.line,
        thickness: SolaSize.hairline,
        space: SolaSize.hairline,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: SolaColors.cream,
        modalBarrierColor: Color(0x591E1612),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SolaRadius.radius34),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        backgroundColor: SolaColors.brown,
        contentTextStyle: SolaTextStyle.body.textStyle(color: SolaColors.cream),
        shape: const StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SolaColors.brown,
        linearTrackColor: SolaColors.track,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: SolaColors.sunDeep,
        selectionColor: SolaColors.butter,
        selectionHandleColor: SolaColors.sunDeep,
      ),
    );
  }
}
