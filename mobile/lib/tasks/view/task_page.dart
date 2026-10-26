import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/cubit/task_cubit.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/tasks/view/task_sheets.dart';
import 'package:solacliq/tasks/view/task_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// One task. What it shows follows its status: to do (photos, checklist,
/// submit), with the admin, returned, on hold with a problem, cancelled,
/// or approved with the next task.
class TaskPage extends StatefulWidget {
  const new({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  TaskCubit get _cubit => context.read<TaskCubit>();

  void _openCamera([String? slotId]) => unawaited(
    context.push(
      AppRoutes.taskCamera(_cubit.taskId, slot: slotId),
      extra: _cubit,
    ),
  );

  void _openHistory() =>
      unawaited(context.push(AppRoutes.taskHistory(_cubit.taskId)));

  Future<void> _submit() async {
    final note = _note.text.trim();
    await _cubit.submit(note: note.isEmpty ? null : note);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<TaskCubit>().state;
    final task = state.task;
    if (task == null) {
      return SolaScreen(
        background: SolaBackground.sand,
        navBar: SolaNavBar(
          leading: const BackTo(fallback: AppRoutes.home),
          title: l10n.taskTitle,
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: SolaSpace.space26),
          child: state.failure == null
              ? const Center(
                  child: CircularProgressIndicator(color: SolaColors.ink),
                )
              : SolaNotice(
                  title: l10n.taskLoadFailed,
                  body: state.failure!.message(l10n),
                  action: SolaButton(
                    key: const Key('task_retry'),
                    label: l10n.retry,
                    variant: SolaButtonVariant.white,
                    compact: true,
                    expand: false,
                    onPressed: () => unawaited(_cubit.load()),
                  ),
                ),
        ),
      );
    }
    if (task.status == TaskStatus.approved) return _Approved(task: task);
    return RefreshIndicator(
      color: SolaColors.ink,
      onRefresh: _cubit.load,
      child: SolaScreen(
        background: SolaBackground.sand,
        navBar: SolaNavBar(
          leading: const BackTo(fallback: AppRoutes.home),
          title: l10n.taskTitle,
          trailing: SolaCircleButton(
            key: const Key('task_history'),
            icon: SolaIcons.history,
            semanticsLabel: l10n.taskHistory,
            onPressed: _openHistory,
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SolaSpace.space14,
          children: [
            const SizedBox(height: SolaSpace.space2),
            if (state.failure case final failure?)
              SolaNotice(
                key: const Key('failure_notice'),
                title: failure.message(l10n),
                announce: true,
              ),
            ?_banner(l10n, task),
            _Header(task: task),
            if (task.status == TaskStatus.cancelled)
              _CancelledHistory(task: task)
            else ...[
              if (task.status == TaskStatus.assigned &&
                  task.problem == null &&
                  !task.ready &&
                  task.adminNote != null)
                SolaBanner(
                  title: l10n.noteFromAdmin,
                  body: task.adminNote!.text,
                  icon: SolaIcons.hourglass,
                  personInitials: initialsOf(task.adminNote!.by.name),
                  personLabel: _who(task.adminNote!.by),
                ),
              if (task.problem == null)
                _Photos(task: task, onTake: _openCamera),
              if (task.ready && task.problem == null)
                SolaGroup(
                  children: [
                    SolaFieldRow(
                      key: const ValueKey('task_note'),
                      label: l10n.noteForAdminOptional,
                      controller: _note,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              if (task.status == TaskStatus.assigned &&
                  task.checklist.isNotEmpty)
                _Checklist(task: task),
              if (task.problem != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SolaSpace.space4,
                  ),
                  child: SolaText(
                    l10n.problemFooter(
                      firstName(task.assignedBy?.name ?? l10n.yourAdmin),
                    ),
                    style: SolaTextStyle.meta,
                    color: SolaColors.muted,
                  ),
                ),
            ],
          ],
        ),
        bottom: _actions(l10n, task, state),
      ),
    );
  }

  String _who(TaskPerson person) => person.role == null
      ? shortName(person.name)
      : '${shortName(person.name)} · ${person.role}';

  Widget? _banner(AppLocalizations l10n, Task task) {
    final admin = firstName(task.assignedBy?.name ?? l10n.yourAdmin);
    final problem = task.problem;
    final returned = task.returned;
    final cancelled = task.cancelled;
    final retakes = task.photos.where((p) => p.retake).length;
    return switch (task.status) {
      TaskStatus.submitted => SolaBanner(
        title: l10n.waitingForApproval,
        body: l10n.waitingBody(
          admin,
          task.submittedAt == null ? '' : formatTime(task.submittedAt!),
        ),
        icon: SolaIcons.hourglass,
      ),
      TaskStatus.returned => SolaBanner(
        title: retakes == 0 ? l10n.returnedTitle : l10n.returnedRetake(retakes),
        body: returned?.text,
        tone: SolaTone.danger,
        icon: SolaIcons.alert,
        personInitials: returned == null ? null : initialsOf(returned.by.name),
        personLabel: returned == null ? null : _who(returned.by),
      ),
      TaskStatus.cancelled => SolaBanner(
        title: l10n.cancelledByAdminTitle,
        body: cancelled?.text,
        tone: SolaTone.quiet,
        icon: SolaIcons.close,
        personInitials: cancelled == null
            ? null
            : initialsOf(cancelled.by.name),
        personLabel: cancelled == null ? null : _who(cancelled.by),
      ),
      TaskStatus.assigned when problem != null => SolaBanner(
        title: l10n.problemSentTo(admin),
        body: l10n.problemSentBody(problem.reason.label(l10n), problem.note),
        tone: SolaTone.warning,
        icon: SolaIcons.pause,
      ),
      _ => null,
    };
  }

  Widget? _actions(AppLocalizations l10n, Task task, TaskState state) {
    final admin = firstName(task.assignedBy?.name ?? l10n.yourAdmin);
    switch (task.status) {
      case TaskStatus.assigned when task.problem == null:
        final missingPhotos = task.photos.length - task.photosDone;
        final missingSteps = task.checklist.length - task.checklistDone;
        return SolaBottomBar(
          children: [
            if (task.ready) ...[
              SolaButton(
                key: const Key('task_submit'),
                label: l10n.submitTask,
                icon: SolaIcons.check,
                onPressed: state.busy ? null : () => unawaited(_submit()),
              ),
              SolaText(
                l10n.submitFooter(admin, firstName(task.customer.name)),
                style: SolaTextStyle.meta,
                color: SolaColors.muted,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              SolaButton(
                key: const Key('task_add_photos'),
                label: missingPhotos > 0
                    ? l10n.addMorePhotos(missingPhotos)
                    : l10n.tickMoreSteps(missingSteps),
                icon: missingPhotos > 0 ? SolaIcons.camera : null,
                onPressed: missingPhotos > 0 ? _openCamera : null,
              ),
              SolaButton(
                key: const Key('task_report_problem'),
                label: l10n.reportProblem,
                variant: SolaButtonVariant.warn,
                icon: SolaIcons.alert,
                onPressed: () => unawaited(showProblemSheet(context, _cubit)),
              ),
            ],
          ],
        );
      case TaskStatus.returned:
        return SolaBottomBar(
          children: [
            SolaButton(
              key: const Key('task_reply'),
              label: l10n.replyTo(admin),
              variant: SolaButtonVariant.link,
              icon: SolaIcons.chat,
              onPressed: () =>
                  unawaited(showReplySheet(context, _cubit, admin)),
            ),
            if (task.nextSlot != null)
              SolaButton(
                key: const Key('task_retake'),
                label: l10n.retakePhotos(task.photos.length - task.photosDone),
                icon: SolaIcons.camera,
                onPressed: () => _openCamera(task.nextSlot!.id),
              )
            else
              SolaButton(
                key: const Key('task_submit'),
                label: l10n.submitAgain,
                icon: SolaIcons.check,
                onPressed: state.busy ? null : () => unawaited(_submit()),
              ),
          ],
        );
      case TaskStatus.assigned ||
          TaskStatus.submitted ||
          TaskStatus.approved ||
          TaskStatus.cancelled:
        return null;
    }
  }
}

/// The task's card: reference, stage, title, its line, the stage bar and
/// the customer with call and directions.
class _Header extends StatelessWidget {
  const new({required this.task});

  final Task task;

  String _line(AppLocalizations l10n) {
    final by = task.assignedBy;
    final due = isToday(task.dueAt)
        ? l10n.dueToday(formatTime(task.dueAt))
        : l10n.dueOn(formatWhen(task.dueAt));
    return switch (task.status) {
      TaskStatus.assigned when task.ready => l10n.readyToSubmit,
      TaskStatus.assigned =>
        by == null ? due : '$due · ${l10n.fromName(firstName(by.name))}',
      TaskStatus.submitted => l10n.submittedLine(
        task.submittedAt == null ? '' : formatTime(task.submittedAt!),
        task.photos.length,
      ),
      TaskStatus.returned => l10n.returnedLine(
        task.returned == null ? '' : formatTime(task.returned!.at),
        task.submittedAt == null ? '' : formatTime(task.submittedAt!),
      ),
      _ => [
        shortName(task.customer.name),
        if (task.customer.systemKw case final kw?) l10n.kwValue(_kw(kw)),
        task.customer.address,
      ].join(' · '),
    };
  }

  static String _kw(double kw) =>
      kw == kw.roundToDouble() ? '${kw.round()}' : '$kw';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cancelled = task.status == TaskStatus.cancelled;
    return SolaCard(
      padding: const EdgeInsets.all(SolaSpace.space18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SolaText(
                  l10n.taskEyebrow(
                    task.reference,
                    task.stageIndex,
                    task.stageCount,
                  ),
                  style: SolaTextStyle.eyebrow,
                  color: SolaColors.muted,
                ),
              ),
              task.status.pill(l10n, hasProblem: task.problem != null),
            ],
          ),
          const SizedBox(height: SolaSpace.space10),
          SolaText(
            task.title,
            style: SolaTextStyle.titleSm,
            color: cancelled ? SolaColors.muted : SolaColors.ink,
          ),
          const SizedBox(height: SolaSpace.space4),
          SolaText(_line(l10n), color: SolaColors.muted),
          if (!cancelled) ...[
            const SizedBox(height: SolaSpace.space12),
            StageBar(index: task.stageIndex, count: task.stageCount),
            const SizedBox(height: SolaSpace.space14),
            const Divider(height: SolaSize.hairline),
            const SizedBox(height: SolaSpace.space12),
            _CustomerRow(customer: task.customer),
          ],
        ],
      ),
    );
  }
}

/// The customer's install stages: done in green, this one in sun.
class StageBar extends StatelessWidget {
  const new({required this.index, required this.count, super.key});

  /// This task's stage, 1-based.
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SolaSegmentBar(
      semanticsLabel: context.l10n.stageOf(index, count),
      segments: [
        for (var i = 1; i <= count; i++)
          SolaSegment(
            1,
            i < index
                ? SolaColors.successDot
                : i == index
                ? SolaColors.sun
                : SolaColors.track,
          ),
      ],
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const new({required this.customer});

  final TaskCustomer customer;

  Future<void> _call() async {
    final phone = customer.phone;
    if (phone == null) return;
    await launchUrl(Uri(scheme: 'tel', path: '+91$phone'));
  }

  Future<void> _directions() async {
    final lat = customer.lat;
    final lng = customer.lng;
    final uri = lat != null && lng != null
        ? Uri.parse('geo:$lat,$lng?q=$lat,$lng')
        : Uri.parse('geo:0,0?q=${Uri.encodeComponent(customer.address)}');
    if (!await launchUrl(uri)) {
      // No maps app for geo: links; open Google Maps on the web.
      await launchUrl(
        Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': lat != null && lng != null ? '$lat,$lng' : customer.address,
        }),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kw = customer.systemKw;
    final name = shortName(customer.name);
    return Row(
      spacing: SolaSpace.space12,
      children: [
        SolaAvatar(initials: initialsOf(customer.name)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SolaSpace.space2,
            children: [
              SolaText(
                kw == null ? name : '$name · ${l10n.kwValue(_Header._kw(kw))}',
                style: SolaTextStyle.rowTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SolaText(
                customer.address,
                style: SolaTextStyle.small,
                color: SolaColors.muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (customer.phone != null)
          SolaCircleButton(
            key: const Key('task_call'),
            icon: SolaIcons.phone,
            semanticsLabel: l10n.callName(name),
            color: SolaColors.tan,
            onPressed: () => unawaited(_call()),
          ),
        SolaCircleButton(
          key: const Key('task_directions'),
          icon: SolaIcons.navigate,
          semanticsLabel: l10n.directions,
          color: SolaColors.sun,
          onPressed: () => unawaited(_directions()),
        ),
      ],
    );
  }
}

/// The task's proof photo slots: taken, to take, or to retake.
class _Photos extends StatelessWidget {
  const new({required this.task, required this.onTake});

  final Task task;
  final ValueChanged<String> onTake;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final retakes = task.photos.where((p) => p.retake).length;
    final (trailing, color) = switch (task.status) {
      TaskStatus.submitted => (l10n.locked, SolaColors.muted),
      TaskStatus.returned when retakes > 0 => (
        l10n.toRetake(retakes),
        SolaColors.danger,
      ),
      _ => (
        l10n.xOfY(task.photosDone, task.photos.length),
        task.photosDone == task.photos.length
            ? SolaColors.success
            : SolaColors.muted,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space10,
      children: [
        SolaSectionHeader(
          l10n.proofPhotos,
          action: SolaText(trailing, color: color),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = SolaSpace.space10;
            final count = task.photos.length.clamp(4, 99);
            final size = ((constraints.maxWidth - gap * 3) / 4).clamp(
              56.0,
              92.0,
            );
            return Wrap(
              spacing: count == 4 ? (constraints.maxWidth - size * 4) / 3 : gap,
              runSpacing: SolaSpace.space12,
              children: [
                for (final slot in task.photos)
                  SolaPhotoTile(
                    key: ValueKey('photo_${slot.id}'),
                    label: slot.label,
                    size: size,
                    image: imageFor(slot.photo?.url),
                    retakeLabel: l10n.retake,
                    state: slot.retake
                        ? SolaPhotoState.retake
                        : slot.photo != null
                        ? SolaPhotoState.done
                        : SolaPhotoState.empty,
                    semanticsLabel: slot.retake
                        ? l10n.photoRetake(slot.label)
                        : slot.photo != null
                        ? l10n.photoAdded(slot.label)
                        : l10n.photoMissing(slot.label),
                    onTap: task.editable && !slot.done
                        ? () => onTake(slot.id)
                        : null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Checklist extends StatelessWidget {
  const new({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TaskCubit>();
    final all = task.checklistDone == task.checklist.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space10,
      children: [
        SolaSectionHeader(
          l10n.checklist,
          action: SolaText(
            l10n.xOfY(task.checklistDone, task.checklist.length),
            color: all ? SolaColors.success : SolaColors.muted,
          ),
        ),
        SolaGroup(
          children: [
            for (final item in task.checklist)
              SolaCheckRow(
                key: ValueKey('check_${item.id}'),
                text: item.text,
                done: item.done,
                onChanged: task.editable && task.problem == null
                    ? (done) =>
                          unawaited(cubit.setChecklistItem(item.id, done: done))
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

/// A cancelled task: what happened to it, from its history.
class _CancelledHistory extends StatefulWidget {
  const new({required this.task});

  final Task task;

  @override
  State<_CancelledHistory> createState() => _CancelledHistoryState();
}

class _CancelledHistoryState extends State<_CancelledHistory> {
  late final Future<List<TaskEvent>> _events = context
      .read<TaskRepository>()
      .history(context.read<TaskCubit>().orgId, widget.task.id);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder(
      future: _events,
      builder: (context, snapshot) {
        final events = snapshot.data?.reversed.toList() ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SolaSpace.space10,
          children: [
            SolaSectionHeader(l10n.whatWasDone),
            if (events.isNotEmpty)
              SolaGroup(
                children: [
                  for (final e in events)
                    SolaListRow(
                      title: e.kind.title(l10n),
                      subtitle:
                          '${e.actor.you ? l10n.you : shortName(e.actor.name)}'
                          ' · ${formatWhen(e.at)}',
                      leading: SolaAvatar(
                        initials: e.actor.you
                            ? l10n.you.substring(0, 1)
                            : initialsOf(e.actor.name),
                        color: SolaColors.brown,
                        foreground: SolaColors.cream,
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SolaSpace.space4),
              child: SolaText(
                l10n.cancelledFooter,
                style: SolaTextStyle.meta,
                color: SolaColors.muted,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// An approved task: the stage moved on, and the next task.
class _Approved extends StatelessWidget {
  const new({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final approval = task.approved!;
    final next = approval.nextTask;
    final nextStage = (task.stageIndex + 1).clamp(1, task.stageCount);
    return SolaScreen(
      background: SolaBackground.sand,
      navBar: const SolaNavBar(
        trailing: BackTo(fallback: AppRoutes.home, close: true),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: SolaSpace.space10),
          SolaSuccessHeader(
            title: l10n.stageApproved(task.stageIndex),
            body: l10n.stageApprovedBody(
              firstName(approval.by.name),
              shortName(task.customer.name),
              nextStage,
            ),
          ),
          const SizedBox(height: SolaSpace.space22),
          SolaProgressCard(
            label: [
              shortName(task.customer.name),
              if (task.customer.systemKw case final kw?)
                l10n.kwValue(_Header._kw(kw)),
            ].join(' · '),
            trailing: l10n.stageOf(nextStage, task.stageCount),
            trailingTone: SolaTone.live,
            segments: [
              for (var i = 1; i <= task.stageCount; i++)
                SolaSegment(
                  1,
                  i < nextStage
                      ? SolaColors.successDot
                      : i == nextStage
                      ? SolaColors.sun
                      : SolaColors.track,
                ),
            ],
            stageLabels: [
              l10n.stageDoneLabel(task.title),
              if (next != null) l10n.stageNextLabel(next.title),
              l10n.stageHandover,
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: SolaSpace.space22),
            SolaSectionHeader(l10n.nextTaskForYou),
            const SizedBox(height: SolaSpace.space10),
            SolaGroup(
              children: [
                SolaListRow(
                  key: ValueKey('next_task_${next.id}'),
                  title: next.title,
                  subtitle: [
                    firstName(next.customerName),
                    formatWhen(next.dueAt),
                  ].join(' · '),
                  leading: SolaThumb(
                    photo: SolaPhotos.fromReference(next.image),
                  ),
                  trailing: next.status.pill(l10n),
                  onTap: () => context.pushReplacement(AppRoutes.task(next.id)),
                ),
              ],
            ),
          ],
        ],
      ),
      bottom: SolaBottomBar(
        children: [
          SolaButton(
            key: const Key('approved_back_to_tasks'),
            label: l10n.backToTasks,
            onPressed: () => context.go(AppRoutes.home),
          ),
          SolaButton(
            key: const Key('approved_history'),
            label: l10n.viewTaskHistory,
            variant: SolaButtonVariant.text,
            icon: SolaIcons.history,
            onPressed: () =>
                unawaited(context.push(AppRoutes.taskHistory(task.id))),
          ),
        ],
      ),
    );
  }
}

extension TaskEventKindText on TaskEventKind {
  String title(AppLocalizations l10n) => switch (this) {
    TaskEventKind.assigned => l10n.eventAssigned,
    TaskEventKind.photosUploaded => l10n.eventPhotos,
    TaskEventKind.submitted => l10n.eventSubmitted,
    TaskEventKind.resubmitted => l10n.eventResubmitted,
    TaskEventKind.returned => l10n.eventReturned,
    TaskEventKind.approved => l10n.eventApproved,
    TaskEventKind.problemReported => l10n.eventProblem,
    TaskEventKind.rescheduled => l10n.eventRescheduled,
    TaskEventKind.reassigned => l10n.eventReassigned,
    TaskEventKind.cancelled => l10n.eventCancelled,
    TaskEventKind.message => l10n.eventMessage,
  };

  /// The dot's colour on the timeline.
  Color get dot => switch (this) {
    TaskEventKind.approved => SolaColors.successDot,
    TaskEventKind.submitted || TaskEventKind.resubmitted => SolaColors.sun,
    TaskEventKind.returned || TaskEventKind.cancelled => SolaColors.dangerDot,
    TaskEventKind.problemReported => SolaColors.warning,
    TaskEventKind.photosUploaded || TaskEventKind.message => SolaColors.avatar,
    _ => SolaColors.faint,
  };
}
