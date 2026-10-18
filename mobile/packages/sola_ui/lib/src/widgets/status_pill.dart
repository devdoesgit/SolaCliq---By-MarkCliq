import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/theme/sola_tone.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';

/// A short status, such as "Approved" or "Pending", on its tone's tint.
class SolaStatusPill extends StatelessWidget {
  /// Creates a status pill.
  const new({required this.label, this.tone = SolaTone.neutral, super.key});

  /// The status word, in sentence case; shown in uppercase.
  final String label;

  /// What the status means.
  final SolaTone tone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: tone.background),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SolaSpace.space2,
          vertical: SolaSpace.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 6,
              child: ColoredBox(color: tone.foreground),
            ),
            const SizedBox(width: SolaSpace.space1),
            SolaText(
              label,
              style: SolaTextStyle.label,
              color: tone.foreground,
              // Regular Space Mono at 11px on a tint measures under 4.5:1.
              fontWeight: FontWeight.w700,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
