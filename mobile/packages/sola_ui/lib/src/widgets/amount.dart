import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/format/money.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';

/// What an amount means, which sets its colour.
enum SolaAmountTone {
  /// A plain amount.
  normal,

  /// A refund or discount; shown with a minus sign, in green.
  credit,

  /// Still to pay; in the accent colour.
  due,
}

/// An amount of money from integer paise: `₹1,85,000.00`.
class SolaAmount extends StatelessWidget {
  /// Creates an amount.
  const new(
    this.paise, {
    this.tone = SolaAmountTone.normal,
    this.large = false,
    super.key,
  });

  /// The amount in paise. Credits are passed positive and shown negative.
  final int paise;

  /// Normal, credit or due.
  final SolaAmountTone tone;

  /// The one headline figure on a screen (balance due, total cost).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final value = tone == SolaAmountTone.credit ? -paise.abs() : paise;
    return SolaText(
      formatPaise(value),
      style: large ? SolaTextStyle.numLg : SolaTextStyle.num,
      color: switch (tone) {
        SolaAmountTone.normal => SolaColors.ink,
        SolaAmountTone.credit => SolaColors.success,
        SolaAmountTone.due => SolaColors.accent,
      },
      maxLines: 1,
    );
  }
}

/// One line of a [SolaAmountSummary].
@immutable
class SolaSummaryLine {
  /// Creates a summary line.
  const new(this.label, this.paise, {this.tone = SolaAmountTone.normal});

  /// What the amount is for: "Panels", "Subsidy".
  final String label;

  /// The amount in paise.
  final int paise;

  /// Normal, credit or due.
  final SolaAmountTone tone;
}

/// A cost breakdown: labelled amounts, then a total under a 1px ink rule.
class SolaAmountSummary extends StatelessWidget {
  /// Creates a summary.
  const new({required this.lines, required this.total, super.key});

  /// The breakdown.
  final List<SolaSummaryLine> lines;

  /// The total, shown last and set apart.
  final SolaSummaryLine total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space2,
      children: [
        for (final line in lines) _Line(line),
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: SolaColors.ink)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: SolaSpace.space2),
            child: _Line(total, bold: true),
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const new(this.line, {this.bold = false});

  final SolaSummaryLine line;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: SolaText(
              line.label,
              fontWeight: bold ? FontWeight.w500 : null,
            ),
          ),
          const SizedBox(width: SolaSpace.space6),
          SolaAmount(line.paise, tone: line.tone),
        ],
      ),
    );
  }
}
