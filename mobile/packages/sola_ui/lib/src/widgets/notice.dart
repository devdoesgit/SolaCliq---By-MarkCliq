import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/theme/sola_tone.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';

/// A message across the screen: what happened and, optionally, one action.
/// Ruled top and bottom in its tone's colour, on its tint.
class SolaNotice extends StatelessWidget {
  /// Creates a notice.
  const new({
    required this.title,
    this.body,
    this.tone = SolaTone.info,
    this.action,
    this.announce = false,
    super.key,
  });

  /// What happened: "No GPS signal".
  final String title;

  /// What to do: "Move into the open and try again."
  final String? body;

  /// Info, warning, danger or success.
  final SolaTone tone;

  /// One action, usually a secondary SolaButton.
  final Widget? action;

  /// Read out by screen readers as soon as it appears (errors).
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    final action = this.action;
    return Semantics(
      container: true,
      liveRegion: announce,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.background,
          border: Border.symmetric(
            horizontal: BorderSide(color: tone.foreground),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SolaSpace.space6,
            vertical: SolaSpace.space3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: SolaSpace.space1,
                  children: [
                    SolaText(
                      title,
                      color: tone.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                    if (body != null)
                      SolaText(body, style: SolaTextStyle.bodySm),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: SolaSpace.space4),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
