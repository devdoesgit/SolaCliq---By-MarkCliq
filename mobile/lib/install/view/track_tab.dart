import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/install/data/install_repository.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/view/task_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// A customer's install, stage by stage, with who visits next.
class TrackTab extends StatefulWidget {
  const new({required this.orgId, super.key});

  final String orgId;

  @override
  State<TrackTab> createState() => TrackTabState();
}

class TrackTabState extends State<TrackTab> {
  late Future<Install> _install = _fetch();

  Future<Install> _fetch() =>
      context.read<InstallRepository>().mine(widget.orgId);

  void reload() => setState(() => _install = _fetch());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RefreshIndicator(
      color: SolaColors.ink,
      onRefresh: () async {
        reload();
        await _install;
      },
      child: SolaScreen(
        background: SolaBackground.sky,
        bottomOverlaps: true,
        navBar: SolaNavBar(title: l10n.yourInstall),
        body: LoadView(
          future: _install,
          failedTitle: l10n.installLoadFailed,
          onRetry: reload,
          builder: (context, install) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SolaSpace.space14,
            children: [
              if (install.nextVisit case final visit?)
                _VisitCard(visit: visit)
              else if (install.handedOver)
                SolaBanner(
                  title: l10n.handedOverAllDone,
                  icon: SolaIcons.sun,
                  tone: SolaTone.success,
                ),
              SolaGroup(
                children: [
                  for (final (i, stage) in install.stages.indexed)
                    SolaListRow(
                      key: ValueKey('stage_$i'),
                      title: l10n.stageNumbered(i + 1, stage.name),
                      subtitle: stage.detail,
                      leading: SolaAvatar(
                        initials: '${i + 1}',
                        color: switch (stage.status) {
                          StageStatus.done => SolaColors.successTint,
                          StageStatus.next => SolaColors.sun,
                          StageStatus.upcoming => SolaColors.track,
                        },
                      ),
                      trailing: switch (stage.status) {
                        StageStatus.done => SolaPill(
                          l10n.stageDone,
                          tone: SolaTone.success,
                          icon: SolaIcons.check,
                        ),
                        StageStatus.next => SolaPill(
                          l10n.stageNext,
                          tone: SolaTone.warning,
                        ),
                        StageStatus.upcoming => null,
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const new({required this.visit});

  final InstallVisit visit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ends = visit.endsAt;
    final phone = visit.personPhone;
    return SolaCard(
      child: Row(
        spacing: SolaSpace.space12,
        children: [
          SolaAvatar(initials: initialsOf(visit.personName)),
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SolaSpace.space2,
                children: [
                  SolaText(
                    l10n.visitsOn(
                      firstName(visit.personName),
                      formatWeekday(visit.startsAt.toLocal()),
                    ),
                    style: SolaTextStyle.rowTitle,
                  ),
                  SolaText(
                    ends == null
                        ? l10n.visitAt(visit.title, formatTime(visit.startsAt))
                        : l10n.visitWindow(
                            visit.title,
                            formatTime(visit.startsAt),
                            formatTime(ends),
                          ),
                    style: SolaTextStyle.small,
                    color: SolaColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (phone != null)
            SolaCircleButton(
              key: const Key('visit_call'),
              icon: SolaIcons.phone,
              semanticsLabel: l10n.callPerson(firstName(visit.personName)),
              onPressed: () => unawaited(launchUrl(Uri.parse('tel:+91$phone'))),
            ),
        ],
      ),
    );
  }
}
