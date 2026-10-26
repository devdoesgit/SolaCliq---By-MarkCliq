import 'dart:ui';

import 'package:sola_ui/src/tokens/tokens.g.dart';

/// The meaning a status pill or notice carries: real status colours, each
/// always shown with a word.
enum SolaTone {
  /// Waiting on someone else, booked, neutral facts: tan.
  neutral(SolaColors.tanText, SolaColors.tan),

  /// Done, approved, verified, good.
  success(SolaColors.success, SolaColors.successTint),

  /// Due, next, needs attention soon.
  warning(SolaColors.warning, SolaColors.warningTint),

  /// Needs a fix, errors.
  danger(SolaColors.danger, SolaColors.dangerTint),

  /// Live and current: the sun accent.
  live(SolaColors.ink, SolaColors.sun),

  /// Strong neutral: a role, an action on a pill.
  dark(SolaColors.cream, SolaColors.brown),

  /// On a photo: ink on white.
  light(SolaColors.ink, SolaColors.surface),

  /// Over and done with, nothing to do: cancelled.
  quiet(SolaColors.muted, SolaColors.segmentTrack);

  new(this.foreground, this.background);

  /// Text and icon colour.
  final Color foreground;

  /// Fill behind the text.
  final Color background;
}
