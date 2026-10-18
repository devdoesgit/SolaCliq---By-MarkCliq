import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';
import 'package:sola_ui/src/widgets/focus_ring.dart';
import 'package:sola_ui/src/widgets/semantics_id.dart';
import 'package:sola_ui/src/widgets/tappable.dart';

/// A row in a list: title, a metadata line, and amounts or a status on the
/// right. Rows are separated by a 1px rule, not boxed.
///
/// A row with [onTap] is interactive and needs a [Key] and a
/// [semanticsLabel].
class SolaListRow extends StatelessWidget {
  /// Creates a list row.
  const new({
    required this.title,
    this.meta,
    this.trailing = const [],
    this.onTap,
    this.semanticsLabel,
    super.key,
  }) : assert(
         onTap == null || (key != null && semanticsLabel != null),
         'A tappable row needs a Key and a semanticsLabel.',
       );

  /// First line, such as the customer's name and system size.
  final String title;

  /// Second line in the label style: stage, date, ID.
  final String? meta;

  /// Shown on the right, stacked: an amount, a status pill.
  final List<Widget> trailing;

  /// Opens the item. Null makes the row static.
  final VoidCallback? onTap;

  /// What a screen reader says for a tappable row, e.g.
  /// "Ramesh Sahoo, 5 kW, quote stage, ₹1,85,000.00 due".
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    if (tap == null) return _content(highlight: false);
    return SolaTappable(
      semanticsLabel: semanticsLabel!,
      identifier: semanticsIdentifier(key),
      onTap: tap,
      builder: (context, state) => SolaFocusRing(
        visible: state.focused,
        inset: true,
        child: _content(highlight: state.pressed || state.hovered),
      ),
    );
  }

  Widget _content({required bool highlight}) {
    final meta = this.meta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlight ? SolaColors.surfaceSunken : null,
        border: const Border(bottom: BorderSide(color: SolaColors.line)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
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
                  children: [
                    SolaText(
                      title,
                      style: SolaTextStyle.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: SolaSpace.space1),
                      SolaText(
                        meta,
                        style: SolaTextStyle.label,
                        color: SolaColors.inkMuted,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing.isNotEmpty) ...[
                const SizedBox(width: SolaSpace.space3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  spacing: SolaSpace.space1,
                  children: trailing,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
