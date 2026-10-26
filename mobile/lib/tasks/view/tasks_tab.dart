import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/cubit/tasks_cubit.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/tasks/view/task_text.dart';

/// The worker's tasks: today, upcoming by day, and done.
class TasksTab extends StatefulWidget {
  const new({this.initialView = TaskView.today, super.key});

  final TaskView initialView;

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  late TaskView _view = widget.initialView;

  @override
  void didUpdateWidget(TasksTab old) {
    super.didUpdateWidget(old);
    if (old.initialView != widget.initialView) _view = widget.initialView;
  }

  void _open(TaskSummary task) {
    final path = task.status == TaskStatus.approved
        ? AppRoutes.taskHistory(task.id)
        : AppRoutes.task(task.id);
    unawaited(
      context
          .push(path)
          .then((_) => mounted ? context.read<TasksCubit>().load() : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<TasksCubit>().state;
    final items = state.lists[_view] ?? const <TaskSummary>[];
    String count(TaskView view) => switch (state.lists[view]?.length) {
      null || 0 => '',
      final n => ' · $n',
    };
    return RefreshIndicator(
      color: SolaColors.ink,
      onRefresh: context.read<TasksCubit>().load,
      child: SolaScreen(
        background: SolaBackground.sand,
        bottomOverlaps: true,
        navBar: SolaNavBar(title: l10n.tabTasks),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SolaSpace.space14,
          children: [
            SolaSegmented<TaskView>(
              key: const ValueKey('tasks_view'),
              label: l10n.tabTasks,
              selected: _view,
              onChanged: (v) => setState(() => _view = v),
              choices: [
                SolaChoice(
                  TaskView.today,
                  '${l10n.tasksToday}${count(TaskView.today)}',
                ),
                SolaChoice(
                  TaskView.upcoming,
                  '${l10n.tasksUpcoming}${count(TaskView.upcoming)}',
                ),
                SolaChoice(TaskView.done, l10n.tasksDone),
              ],
            ),
            if (state.failure case final failure? when items.isEmpty)
              SolaNotice(
                title: l10n.tasksLoadFailed,
                body: failure.message(l10n),
                action: SolaButton(
                  key: const Key('tasks_retry'),
                  label: l10n.retry,
                  variant: SolaButtonVariant.white,
                  compact: true,
                  expand: false,
                  onPressed: () => unawaited(context.read<TasksCubit>().load()),
                ),
              )
            else if (state.loading)
              const Padding(
                padding: EdgeInsets.only(top: SolaSpace.space34),
                child: Center(
                  child: CircularProgressIndicator(color: SolaColors.ink),
                ),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: SolaSpace.space26),
                child: SolaText(
                  switch (_view) {
                    TaskView.today => l10n.noTasksToday,
                    TaskView.upcoming => l10n.noTasksUpcoming,
                    TaskView.done => l10n.noTasksDone,
                  },
                  color: SolaColors.muted,
                  textAlign: TextAlign.center,
                ),
              )
            else if (_view == TaskView.upcoming)
              for (final day in _byDay(items).entries) ...[
                SolaSectionLabel(formatWeekdayDate(day.key)),
                _TaskGroup(tasks: day.value, onOpen: _open, showDay: true),
              ]
            else
              _TaskGroup(tasks: items, onOpen: _open),
            if (items.isNotEmpty && _view != TaskView.upcoming)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SolaSpace.space4,
                ),
                child: SolaText(
                  _view == TaskView.today
                      ? l10n.tasksTodayFooter
                      : l10n.tasksDoneFooter,
                  style: SolaTextStyle.small,
                  color: SolaColors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Map<DateTime, List<TaskSummary>> _byDay(List<TaskSummary> tasks) {
    final days = <DateTime, List<TaskSummary>>{};
    for (final task in tasks) {
      final local = task.dueAt.toLocal();
      days
          .putIfAbsent(DateTime(local.year, local.month, local.day), () => [])
          .add(task);
    }
    return days;
  }
}

class _TaskGroup extends StatelessWidget {
  const new({required this.tasks, required this.onOpen, this.showDay = false});

  final List<TaskSummary> tasks;
  final ValueChanged<TaskSummary> onOpen;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SolaGroup(
      children: [
        for (final task in tasks)
          SolaListRow(
            key: ValueKey('task_row_${task.id}'),
            title: shortName(task.customerName),
            subtitle: task.line(l10n, showDay: showDay),
            leading: SolaThumb(photo: SolaPhotos.fromReference(task.image)),
            trailing: task.status.pill(l10n, hasProblem: task.hasProblem),
            onTap: () => onOpen(task),
          ),
      ],
    );
  }
}
