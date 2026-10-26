import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/notifications/data/notification_repository.dart';
import 'package:solacliq/tasks/view/task_text.dart';

/// What changed for the person in this company (tasks, expenses,
/// customers, their install), or with no [orgId] their own quotes,
/// invites and guides. One that belongs to a tab of the home closes the
/// page with that tab's key ([NotificationTab]).
class NotificationsPage extends StatefulWidget {
  const new({
    required this.orgId,
    this.background = SolaBackground.sand,
    this.asTab = false,
    super.key,
  });

  final String? orgId;
  final SolaBackground background;

  /// Shown as a tab of the home (no back button) rather than on its own.
  final bool asTab;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<AppNotification>? _items;
  AuthFailureCode? _failure;

  NotificationRepository get _repo => context.read<NotificationRepository>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final items = await _repo.list(widget.orgId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _failure = null;
      });
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _failure = failure.code);
    }
  }

  Future<void> _readAll() async {
    final items = _items;
    if (items == null) return;
    setState(() => _items = [for (final n in items) n.markRead()]);
    final orgId = widget.orgId;
    // The person's own notifications are marked read as they are opened.
    if (orgId == null) return;
    try {
      await _repo.markAllRead(orgId);
    } on AuthFailure {
      // Not important enough to stop the person; the dots return on reload.
    }
  }

  void _open(AppNotification n) {
    final path = destination(n);
    if (path == null) return;
    setState(() {
      _items = [
        for (final m in _items ?? const <AppNotification>[])
          if (m.id == n.id) m.markRead() else m,
      ];
    });
    if (NotificationTab.values.asNameMap()[path] case final tab?) {
      context.pop(tab);
    } else {
      unawaited(context.push(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = _items;
    final today = [
      for (final n in items ?? const <AppNotification>[])
        if (isToday(n.at)) n,
    ];
    final earlier = [
      for (final n in items ?? const <AppNotification>[])
        if (!isToday(n.at)) n,
    ];
    return RefreshIndicator(
      color: SolaColors.ink,
      onRefresh: _load,
      child: SolaScreen(
        background: widget.background,
        bottomOverlaps: widget.asTab,
        navBar: SolaNavBar(
          leading: widget.asTab ? null : const BackTo(fallback: AppRoutes.home),
          title: l10n.notifications,
          trailing: switch (items) {
            final items? when items.any((n) => !n.read) => SolaTextLink(
              l10n.readAll,
              key: const Key('notifications_read_all'),
              style: SolaTextStyle.body,
              onPressed: () => unawaited(_readAll()),
            ),
            _ => null,
          },
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SolaSpace.space10,
          children: [
            const SizedBox(height: SolaSpace.space4),
            if (_failure case final failure? when items == null)
              SolaNotice(
                title: l10n.notificationsLoadFailed,
                body: failure.message(l10n),
                action: SolaButton(
                  key: const Key('notifications_retry'),
                  label: l10n.retry,
                  variant: SolaButtonVariant.white,
                  compact: true,
                  expand: false,
                  onPressed: () => unawaited(_load()),
                ),
              )
            else if (items == null)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(color: SolaColors.ink),
                ),
              )
            else if (items.isEmpty)
              SolaText(
                l10n.noNotifications,
                color: SolaColors.muted,
                textAlign: TextAlign.center,
              )
            else ...[
              if (today.isNotEmpty) ...[
                SolaSectionLabel(l10n.todayTitle),
                _Group(items: today, onOpen: _open),
              ],
              if (earlier.isNotEmpty) ...[
                const SizedBox(height: SolaSpace.space4),
                SolaSectionLabel(l10n.earlier),
                _Group(items: earlier, onOpen: _open),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const new({required this.items, required this.onOpen});

  final List<AppNotification> items;
  final ValueChanged<AppNotification> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SolaGroup(
      children: [
        for (final n in items)
          SolaListRow(
            key: ValueKey('notification_${n.id}'),
            title: n.title,
            subtitle: n.body,
            subtitleLines: 2,
            semanticsLabel: n.read
                ? '${n.title}. ${n.body}'
                : '${l10n.unread}. ${n.title}. ${n.body}',
            leading: _Icon(kind: n.kind),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: SolaSpace.space6,
              children: [
                SolaText(
                  formatAgo(n.at),
                  style: SolaTextStyle.meta,
                  color: SolaColors.muted,
                ),
                if (!n.read)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: SolaColors.sunDeep,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            onTap: destination(n) == null ? null : () => onOpen(n),
          ),
      ],
    );
  }
}

class _Icon extends StatelessWidget {
  const new({required this.kind});

  final NotificationKind kind;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (kind) {
      NotificationKind.taskApproved => (SolaIcons.check, SolaTone.success),
      NotificationKind.taskReturned => (SolaIcons.alert, SolaTone.danger),
      NotificationKind.taskAssigned => (SolaIcons.list, SolaTone.warning),
      NotificationKind.taskCancelled => (SolaIcons.close, SolaTone.quiet),
      NotificationKind.taskRescheduled => (SolaIcons.alarm, SolaTone.warning),
      NotificationKind.expenseApproved ||
      NotificationKind.expensePaid => (SolaIcons.receipt, SolaTone.success),
      NotificationKind.expenseReturned => (SolaIcons.receipt, SolaTone.danger),
      NotificationKind.kycReturned => (SolaIcons.alert, SolaTone.danger),
      NotificationKind.kycSubmitted => (SolaIcons.hourglass, SolaTone.quiet),
      NotificationKind.kycApproved ||
      NotificationKind.documentsVerified => (SolaIcons.check, SolaTone.success),
      NotificationKind.installStarted => (SolaIcons.sun, SolaTone.warning),
      NotificationKind.commissionChanged => (
        SolaIcons.wallet,
        SolaTone.warning,
      ),
      NotificationKind.commissionPayable ||
      NotificationKind.commissionPaid => (SolaIcons.wallet, SolaTone.success),
      NotificationKind.visitBooked => (SolaIcons.alarm, SolaTone.warning),
      NotificationKind.paymentDue => (SolaIcons.wallet, SolaTone.danger),
      NotificationKind.quoteShared => (SolaIcons.sun, SolaTone.success),
      NotificationKind.inviteReceived => (SolaIcons.building, SolaTone.warning),
      NotificationKind.guide => (SolaIcons.file, SolaTone.quiet),
    };
    return SolaAvatar(
      icon: icon,
      color: tone.background,
      foreground: tone.foreground,
    );
  }
}

/// Home tabs a notification can open; the page closes with one of these.
enum NotificationTab { track, payments }

/// Where [n] leads: a route, a [NotificationTab]'s name, or null.
@visibleForTesting
String? destination(AppNotification n) => switch (n) {
  AppNotification(:final taskId?) => AppRoutes.task(taskId),
  AppNotification(:final expenseId?) => AppRoutes.expenseDetail(expenseId),
  AppNotification(:final customerId?) => AppRoutes.customer(customerId),
  AppNotification(kind: NotificationKind.guide) => AppRoutes.learn,
  AppNotification(kind: NotificationKind.documentsVerified) =>
    AppRoutes.documents,
  AppNotification(kind: NotificationKind.visitBooked) =>
    NotificationTab.track.name,
  AppNotification(kind: NotificationKind.paymentDue) =>
    NotificationTab.payments.name,
  _ => null,
};
