import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/format/date.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';

/// Where a stage is in the installation.
enum SolaStageState {
  /// Finished.
  done,

  /// In progress now. Only one stage is current.
  current,

  /// Not started.
  upcoming,
}

/// One stage of an installation, such as "Site survey".
@immutable
class SolaStage {
  /// Creates a stage.
  const new({required this.name, required this.state, this.date});

  /// Stage name, as solar vendors say it.
  final String name;

  /// Done, current or upcoming.
  final SolaStageState state;

  /// When it was done, or when the current stage started.
  final DateTime? date;
}

/// The numbered list of install stages, with the current one highlighted.
class SolaStageTracker extends StatelessWidget {
  /// Creates a stage tracker.
  const new({required this.stages, super.key});

  /// Stages in order.
  final List<SolaStage> stages;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SolaColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stages.length; i++)
            _StageRow(stage: stages[i], number: i + 1, total: stages.length),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const new({required this.stage, required this.number, required this.total});

  final SolaStage stage;
  final int number;
  final int total;

  @override
  Widget build(BuildContext context) {
    final current = stage.state == SolaStageState.current;
    final done = stage.state == SolaStageState.done;
    final date = stage.date;
    final numberColor = switch (stage.state) {
      SolaStageState.done => SolaColors.success,
      SolaStageState.current => SolaColors.accent,
      SolaStageState.upcoming => SolaColors.inkMuted,
    };
    final stateWord = switch (stage.state) {
      SolaStageState.done => 'done',
      SolaStageState.current => 'current',
      SolaStageState.upcoming => 'not started',
    };

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: [
        'Stage $number of $total: ${stage.name}, $stateWord',
        if (date != null) formatDate(date),
      ].join(', '),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: current ? SolaColors.accentTint : null,
          border: const Border(bottom: BorderSide(color: SolaColors.line)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SolaSize.tapMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SolaSpace.space3,
              vertical: SolaSpace.space2,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: SolaText(
                    number.toString().padLeft(2, '0'),
                    style: SolaTextStyle.label,
                    color: numberColor,
                  ),
                ),
                const SizedBox(width: SolaSpace.space3),
                Expanded(
                  child: SolaText(
                    stage.name,
                    color: current || done
                        ? SolaColors.ink
                        : SolaColors.inkMuted,
                    fontWeight: current ? FontWeight.w500 : null,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(width: SolaSpace.space3),
                  SolaText(
                    formatDate(date),
                    style: SolaTextStyle.label,
                    color: current ? SolaColors.accent : SolaColors.inkMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
