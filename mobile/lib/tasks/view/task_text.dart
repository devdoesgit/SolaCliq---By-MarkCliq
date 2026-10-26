import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/data/task_repository.dart';

/// "9:30", "13:00": 24-hour, as the designs write times.
String formatTime(DateTime at) {
  final local = at.toLocal();
  return '${local.hour}:${local.minute.toString().padLeft(2, '0')}';
}

/// "Mon, 20 Oct".
String formatWeekdayDate(DateTime at) {
  final local = at.toLocal();
  return '${formatWeekday(local)}, ${formatDayMonth(local)}';
}

/// "Fri 24 Oct, 10:00".
String formatWhen(DateTime at) {
  final local = at.toLocal();
  return '${formatWeekday(local)} ${formatDayMonth(local)}, '
      '${formatTime(local)}';
}

bool isToday(DateTime at) => DateUtils.isSameDay(at.toLocal(), DateTime.now());

/// "12:10" today, "Tue" this week, "18 Oct" before.
String formatAgo(DateTime at) {
  final local = at.toLocal();
  final days = DateUtils.dateOnly(DateTime.now())
      .difference(DateUtils.dateOnly(local))
      .inDays;
  if (days == 0) return formatTime(local);
  if (days < 7) return formatWeekday(local);
  return formatDayMonth(local);
}

/// Initials of a name, ignoring notes in brackets: "RS".
String initialsOf(String name) {
  final words = name
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty);
  return words.take(2).map((w) => w[0].toUpperCase()).join();
}

/// A name as shown. Sample names keep their "(illustrative)" note, so
/// demo data is always labelled.
String shortName(String name) => name.trim();

/// The first name, for running text: "Rajeeb".
String firstName(String name) => name.trim().split(' ').first;

/// Bundled sample pictures (`asset:`), photos just taken (`file:`), or
/// links from the server.
ImageProvider? imageFor(String? reference) {
  if (reference == null) return null;
  if (SolaPhotos.fromReference(reference) case final photo?) {
    return photo.provider;
  }
  if (reference.startsWith('file:')) {
    return ResizeImage(FileImage(File(reference.substring(5))), width: 400);
  }
  if (reference.startsWith('http')) return NetworkImage(reference);
  return null;
}

extension TaskStatusText on TaskStatus {
  /// The status pill for a task, or [hasProblem] for an open problem.
  SolaPill pill(AppLocalizations l10n, {bool hasProblem = false}) =>
      switch (this) {
        TaskStatus.assigned when hasProblem => SolaPill(
          l10n.taskOnHold,
          tone: SolaTone.warning,
          icon: SolaIcons.pause,
        ),
        TaskStatus.assigned => SolaPill(l10n.taskAssigned, tone: SolaTone.live),
        TaskStatus.submitted => SolaPill(l10n.statusInReview),
        TaskStatus.returned => SolaPill(
          l10n.taskReturned,
          tone: SolaTone.danger,
          icon: SolaIcons.alarm,
        ),
        TaskStatus.approved => SolaPill(
          l10n.taskDone,
          tone: SolaTone.success,
          icon: SolaIcons.check,
        ),
        TaskStatus.cancelled => SolaPill(
          l10n.taskCancelled,
          tone: SolaTone.quiet,
        ),
      };
}

extension TaskSummaryText on TaskSummary {
  /// The line under the customer's name in a list.
  String line(AppLocalizations l10n, {bool showDay = false}) {
    final when = showDay ? formatTime(dueAt) : l10n.dueAt(formatTime(dueAt));
    final distance = distanceKm == null
        ? null
        : l10n.distanceKm(distanceKm!.toStringAsFixed(1).replaceAll('.0', ''));
    final at = statusAt;
    return switch (status) {
      TaskStatus.assigned when hasProblem => '$title · ${l10n.problemSent}',
      TaskStatus.assigned => [title, when, ?distance].join(' · '),
      TaskStatus.returned => '$title · ${l10n.retakeAsked}',
      TaskStatus.submitted =>
        '$title · ${l10n.sentAt(at == null ? '' : formatTime(at))}',
      TaskStatus.approved =>
        '$title · ${l10n.approvedOn(at == null ? '' : formatDayMonth(at))}',
      TaskStatus.cancelled => '$title · ${l10n.cancelledByAdmin}',
    };
  }
}

extension TaskProblemReasonText on TaskProblemReason {
  String label(AppLocalizations l10n) => switch (this) {
    TaskProblemReason.customerAway => l10n.problemCustomerAway,
    TaskProblemReason.materialMissing => l10n.problemMaterialMissing,
    TaskProblemReason.badWeather => l10n.problemBadWeather,
    TaskProblemReason.siteNotReady => l10n.problemSiteNotReady,
    TaskProblemReason.safety => l10n.problemSafety,
    TaskProblemReason.other => l10n.problemOther,
  };
}
