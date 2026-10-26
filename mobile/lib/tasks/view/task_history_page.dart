import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/tasks/view/task_page.dart';
import 'package:solacliq/tasks/view/task_text.dart';

/// Everything that happened to a task, newest first. Kept for every task;
/// nobody can edit it.
class TaskHistoryPage extends StatefulWidget {
  const new({required this.orgId, required this.taskId, super.key});

  final String orgId;
  final String taskId;

  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  late Future<(Task, List<TaskEvent>)> _load = _fetch();

  Future<(Task, List<TaskEvent>)> _fetch() async {
    final tasks = context.read<TaskRepository>();
    final results = await (
      tasks.get(widget.orgId, widget.taskId),
      tasks.history(widget.orgId, widget.taskId),
    ).wait;
    return results;
  }

  String _summary(AppLocalizations l10n, List<TaskEvent> events) {
    DateTime? at(TaskEventKind kind) {
      for (final e in events.reversed) {
        if (e.kind == kind) return e.at;
      }
      return null;
    }

    final assigned = at(TaskEventKind.assigned);
    final approved = at(TaskEventKind.approved);
    final returns = events.where((e) => e.kind == TaskEventKind.returned);
    return [
      if (assigned != null) l10n.assignedOn(formatDayMonth(assigned)),
      if (approved != null) l10n.approvedOn(formatDayMonth(approved)),
      if (returns.isNotEmpty) l10n.returnCount(returns.length),
    ].join(' · ');
  }

  static String _subtitle(AppLocalizations l10n, TaskEvent e) {
    final who = e.actor.you ? l10n.you : shortName(e.actor.name);
    final when = isToday(e.at) ? formatTime(e.at) : formatWhen(e.at);
    return '$who · $when';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder(
      future: _load,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final task = data?.$1;
        return SolaScreen(
          background: SolaBackground.sand,
          navBar: SolaNavBar(
            leading: const BackTo(fallback: AppRoutes.home),
            title: l10n.history,
            subtitle: task == null
                ? null
                : '${task.reference} · ${shortName(task.customer.name)}',
          ),
          body: switch (snapshot) {
            AsyncSnapshot(:final Object error) => Padding(
              padding: const EdgeInsets.only(top: SolaSpace.space26),
              child: SolaNotice(
                title: l10n.historyLoadFailed,
                body: error is AuthFailure ? error.code.message(l10n) : null,
                action: SolaButton(
                  key: const Key('history_retry'),
                  label: l10n.retry,
                  variant: SolaButtonVariant.white,
                  compact: true,
                  expand: false,
                  onPressed: () => setState(() {
                    _load = _fetch();
                  }),
                ),
              ),
            ),
            AsyncSnapshot(data: (final task, final events)?) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SolaSpace.space14,
              children: [
                const SizedBox(height: SolaSpace.space2),
                SolaCard(
                  padding: const EdgeInsets.all(SolaSpace.space18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: SolaSpace.space10,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SolaText(
                              task.title,
                              style: SolaTextStyle.eyebrow,
                              color: SolaColors.muted,
                            ),
                          ),
                          if (task.status == TaskStatus.approved)
                            SolaPill(
                              l10n.statusApproved,
                              tone: SolaTone.success,
                              icon: SolaIcons.check,
                            )
                          else
                            task.status.pill(l10n),
                        ],
                      ),
                      SolaText(
                        _summary(l10n, events),
                        style: SolaTextStyle.small,
                        color: SolaColors.muted,
                      ),
                    ],
                  ),
                ),
                SolaCard(
                  padding: const EdgeInsets.fromLTRB(
                    SolaSpace.space18,
                    SolaSpace.space20,
                    SolaSpace.space18,
                    SolaSpace.space2,
                  ),
                  child: SolaTimeline(
                    entries: [
                      for (final e in events)
                        SolaTimelineEntry(
                          title: e.kind.title(l10n),
                          subtitle: _subtitle(l10n, e),
                          detail: e.detail,
                          dot: e.kind.dot,
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: SolaSpace.space6,
                  children: [
                    const SolaIcon(
                      SolaIcons.lock,
                      size: 12,
                      color: SolaColors.muted,
                    ),
                    Flexible(
                      child: SolaText(
                        l10n.historyFooter,
                        style: SolaTextStyle.meta,
                        color: SolaColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _ => const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(
                child: CircularProgressIndicator(color: SolaColors.ink),
              ),
            ),
          },
        );
      },
    );
  }
}
