import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';
import 'package:sola_ui/src/widgets/focus_ring.dart';
import 'package:sola_ui/src/widgets/semantics_id.dart';
import 'package:sola_ui/src/widgets/tappable.dart';

/// What a [SolaButton] is for.
enum SolaButtonVariant {
  /// The one primary action on a screen. Accent fill.
  primary,

  /// Any other action. Outlined.
  secondary,

  /// Low-emphasis action, such as "Cancel" or a link-like action. Accent
  /// text, no border.
  ghost,

  /// Destructive action. Danger outline.
  danger,
}

/// A SolaCliq button: at least 48dp tall, square corners, immediate pressed
/// state.
///
/// Every button needs a [Key] so it can be found in tests and by mobile-mcp.
class SolaButton extends StatelessWidget {
  /// Creates a button. A null [onPressed] disables it.
  const new({
    required Key super.key,
    required this.label,
    required this.onPressed,
    this.variant = SolaButtonVariant.secondary,
    this.expand = false,
    this.semanticsLabel,
  });

  /// The visible label, in sentence case: "Save expense".
  final String label;

  /// Called when tapped. Null shows the disabled style.
  final VoidCallback? onPressed;

  /// Primary, secondary, ghost or danger.
  final SolaButtonVariant variant;

  /// Fill the available width (the primary action at the bottom of a
  /// mobile screen).
  final bool expand;

  /// Spoken label when [label] alone isn't clear, e.g. "Delete receipt 2".
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SolaTappable(
      semanticsLabel: semanticsLabel ?? label,
      identifier: semanticsIdentifier(key),
      onTap: onPressed,
      builder: (context, state) {
        final colors = _ButtonColors.of(variant, state);
        return SolaFocusRing(
          visible: state.focused,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: SolaSize.tapMin,
              minWidth: expand ? double.infinity : SolaSize.tapMin,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.fill,
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: variant == SolaButtonVariant.ghost
                      ? SolaSpace.space3
                      : SolaSpace.space10,
                  vertical: SolaSpace.space4,
                ),
                child: Center(
                  widthFactor: expand ? null : 1,
                  child: SolaText(
                    label,
                    style: SolaTextStyle.button,
                    color: colors.text,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ButtonColors {
  const new(this.fill, this.border, this.text);

  factory of(SolaButtonVariant variant, SolaTapState state) {
    if (!state.enabled) {
      return const _ButtonColors(
        SolaColors.surfaceSunken,
        SolaColors.line,
        SolaColors.inkMuted,
      );
    }
    final active = state.pressed || state.hovered;
    const clear = Color(0x00000000);
    return switch (variant) {
      SolaButtonVariant.primary => _ButtonColors(
        active ? SolaColors.accentStrong : SolaColors.accent,
        active ? SolaColors.accentStrong : SolaColors.accent,
        SolaColors.onAccent,
      ),
      SolaButtonVariant.secondary => _ButtonColors(
        active ? SolaColors.surfaceSunken : clear,
        SolaColors.lineStrong,
        SolaColors.ink,
      ),
      SolaButtonVariant.ghost => _ButtonColors(
        active ? SolaColors.accentTint : clear,
        clear,
        SolaColors.accent,
      ),
      SolaButtonVariant.danger => _ButtonColors(
        active ? SolaColors.dangerTint : clear,
        SolaColors.danger,
        SolaColors.danger,
      ),
    };
  }

  final Color fill;
  final Color border;
  final Color text;
}
