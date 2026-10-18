import 'dart:ui';

import 'package:sola_ui/src/tokens/tokens.g.dart';

/// The meaning a status pill or notice carries. Always shown with a word,
/// never colour alone.
enum SolaTone {
  /// No particular state.
  neutral(SolaColors.ink, SolaColors.surfaceSunken),

  /// Approved, completed, synced.
  success(SolaColors.success, SolaColors.successTint),

  /// Flagged for review, waiting to sync.
  warning(SolaColors.warning, SolaColors.warningTint),

  /// Rejected, suspended, errors.
  danger(SolaColors.danger, SolaColors.dangerTint),

  /// Pending, waiting on someone else.
  info(SolaColors.info, SolaColors.infoTint),

  /// The current item, such as the current install stage.
  accent(SolaColors.accent, SolaColors.accentTint);

  new(this.foreground, this.background);

  /// Text, dot and rule colour.
  final Color foreground;

  /// Tint behind the text.
  final Color background;
}
