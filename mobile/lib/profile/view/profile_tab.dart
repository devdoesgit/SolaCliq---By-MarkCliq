import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/account/widgets/log_out_bar.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/app/widgets/help_sheet.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/install/data/install_repository.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/notifications/view/notifications_page.dart';
import 'package:solacliq/profile/data/profile_repository.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/workspace/data/workspace.dart';
import 'package:solacliq/workspace/view/workspace_sheet.dart';

/// A profile stat: "5" over "customers".
typedef ProfileStat = ({String value, String label});

/// The person's profile in the workspace in use: who they are and where,
/// this month in three numbers, what they can open for their role, and
/// workspaces, help and log out. With no [workspace], the Personal one.
class ProfileTab extends StatefulWidget {
  const new({
    required this.account,
    this.workspace,
    this.onTaskHistory,
    this.onTab,
    this.pushed = false,
    super.key,
  });

  final Account account;
  final MemberWorkspace? workspace;

  /// A worker's Done tasks.
  final VoidCallback? onTaskHistory;

  /// Opens a home tab a notification leads to.
  final ValueChanged<NotificationTab>? onTab;

  /// Opened on its own, with a back button, rather than as a tab.
  final bool pushed;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late Future<List<ProfileStat>> _stats = _fetchStats();
  late Future<PersonalDetails>? _details = _wantsBank
      ? context.read<ProfileRepository>().details()
      : null;

  MemberWorkspace? get _workspace => widget.workspace;

  bool get _wantsBank => _workspace?.earnsCommission ?? false;

  Future<List<ProfileStat>> _fetchStats() async {
    final l10n = context.l10n;
    final workspace = _workspace;
    if (workspace == null) return const [];
    switch (workspace.role) {
      case OrgRole.worker:
        final s = await context.read<TaskRepository>().stats(workspace.orgId);
        return [
          (value: '${s.tasksThisMonth}', label: l10n.tasksThisMonth),
          (value: '${s.returnedThisMonth}', label: l10n.returnedLabel),
          (
            value: l10n.hoursValue(
              (s.avgMinutesOnSite / 60).toStringAsFixed(1),
            ),
            label: l10n.avgOnSite,
          ),
        ];
      case OrgRole.agent:
        final all = await context.read<CustomerRepository>().mine(
          workspace.orgId,
        );
        final count = (value: '${all.length}', label: l10n.statCustomers);
        if (!workspace.earnsCommission) {
          return [
            count,
            (
              value: '${all.where((c) => c.kyc == KycStatus.approved).length}',
              label: l10n.statApproved,
            ),
            (
              value: '${all.where((c) => c.kyc == KycStatus.needsFix).length}',
              label: l10n.statToFix,
            ),
          ];
        }
        final now = DateTime.now();
        int sum(bool Function(Commission c) test) => all
            .map((c) => c.commission)
            .whereType<Commission>()
            .where(test)
            .fold(0, (t, c) => t + c.amountPaise);
        return [
          count,
          (
            value: formatThousands(
              sum(
                (c) =>
                    c.status == CommissionStatus.paid &&
                    c.paidOn?.month == now.month &&
                    c.paidOn?.year == now.year,
              ),
            ),
            label: l10n.statPaidIn(DateFormat.MMM().format(now)),
          ),
          (
            value: formatThousands(
              sum((c) => c.status == CommissionStatus.payable),
            ),
            label: l10n.statPayable,
          ),
        ];
      case OrgRole.customer:
        final i = await context.read<InstallRepository>().mine(workspace.orgId);
        return [
          (value: '${i.systemKw} kW', label: l10n.statSystem),
          (value: '${i.stageIndex}/${i.stageCount}', label: l10n.statStage),
          (value: formatThousands(i.subsidyPaise), label: l10n.statSubsidy2),
        ];
      case OrgRole.orgAdmin:
        return const [];
    }
  }

  Future<void> _push(String path) async {
    final result = await context.push(path);
    if (result is NotificationTab) widget.onTab?.call(result);
    if (!mounted) return;
    setState(() {
      _stats = _fetchStats();
      if (_wantsBank) _details = context.read<ProfileRepository>().details();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final account = widget.account;
    final workspace = _workspace;
    final role = workspace?.role;
    NavRow row(
      String key,
      SolaIcons icon,
      String title,
      String? sub,
      String path,
    ) => NavRow(
      key: Key(key),
      icon: icon,
      title: title,
      subtitle: sub,
      onTap: () => unawaited(_push(path)),
    );
    final notifications = row(
      'profile_notifications',
      SolaIcons.bell,
      l10n.notifications,
      switch (role) {
        OrgRole.customer => l10n.notificationsSubCustomer,
        OrgRole.agent => l10n.notificationsSubSales,
        _ => l10n.notificationsSubUser,
      },
      AppRoutes.notifications,
    );
    final rows = switch (role) {
      OrgRole.worker => [
        row(
          'profile_details',
          SolaIcons.user,
          l10n.personalDetails,
          l10n.personalDetailsSub,
          AppRoutes.details,
        ),
        row(
          'profile_documents',
          SolaIcons.idCard,
          l10n.idDocuments,
          l10n.idDocumentsSub,
          AppRoutes.documents,
        ),
        NavRow(
          key: const Key('profile_task_history'),
          icon: SolaIcons.history,
          title: l10n.taskHistory,
          subtitle: l10n.taskHistorySub,
          onTap: widget.onTaskHistory,
        ),
      ],
      OrgRole.agent when workspace!.earnsCommission => [
        NavRow(
          key: const Key('profile_bank'),
          icon: SolaIcons.wallet,
          title: l10n.bankForPayouts,
          onTap: () => unawaited(_push(AppRoutes.bank)),
          trailing: _BankLine(details: _details),
        ),
        notifications,
      ],
      OrgRole.agent => const <Widget>[],
      OrgRole.customer => [
        row(
          'profile_documents',
          SolaIcons.file,
          l10n.documentsLabel,
          l10n.documentsSubCustomer,
          AppRoutes.documents,
        ),
        notifications,
      ],
      _ => [notifications],
    };
    return SolaScreen(
      background: switch (role) {
        OrgRole.agent => SolaBackground.stone,
        OrgRole.customer => SolaBackground.sky,
        null => SolaBackground.cream,
        _ => SolaBackground.sand,
      },
      bottomOverlaps: !widget.pushed,
      navBar: SolaNavBar(
        leading: widget.pushed ? const BackTo(fallback: AppRoutes.home) : null,
        title: l10n.tabProfile,
        trailing: SolaCircleButton(
          key: const Key('profile_settings'),
          icon: SolaIcons.settings,
          semanticsLabel: l10n.settings,
          onPressed: () => unawaited(context.push(AppRoutes.settings)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SolaSpace.space14,
        children: [
          const SizedBox(height: SolaSpace.space4),
          Column(
            spacing: SolaSpace.space10,
            children: [
              SolaAvatar(initials: account.initials, size: 72),
              SolaText(account.name, style: SolaTextStyle.titleSm),
              Wrap(
                spacing: SolaSpace.space6,
                runSpacing: SolaSpace.space6,
                alignment: WrapAlignment.center,
                children: [
                  if (workspace == null)
                    SolaPill(l10n.solacliqUser, tone: SolaTone.dark)
                  else ...[
                    SolaPill(workspace.role.label(l10n), tone: SolaTone.dark),
                    if (role == OrgRole.agent)
                      SolaPill(
                        workspace.earnsCommission
                            ? l10n.payCommission
                            : l10n.paySalaried,
                      ),
                    SolaPill(workspace.orgName),
                  ],
                ],
              ),
            ],
          ),
          if (workspace != null)
            FutureBuilder(
              future: _stats,
              builder: (context, snapshot) {
                final stats = snapshot.data;
                if (stats == null || stats.isEmpty) {
                  return const SizedBox.shrink();
                }
                return SolaCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: SolaSpace.space16,
                  ),
                  child: Row(
                    children: [
                      for (final s in stats)
                        _Stat(value: s.value, label: s.label),
                    ],
                  ),
                );
              },
            ),
          if (rows.isNotEmpty) SolaGroup(children: rows),
          SolaGroup(
            children: [
              NavRow(
                key: const Key('profile_workspaces'),
                icon: SolaIcons.building,
                title: l10n.workspaces,
                subtitle: workspace == null
                    ? l10n.personal
                    : l10n.workspacesSub(workspace.orgName),
                onTap: () => unawaited(showWorkspaceSheet(context)),
              ),
              NavRow(
                key: const Key('profile_help'),
                icon: SolaIcons.help,
                title: l10n.help,
                subtitle: l10n.helpSub,
                onTap: () => unawaited(
                  showHelpSheet(
                    context,
                    orgName: workspace?.orgName,
                    orgPhone: workspace?.orgPhone,
                  ),
                ),
              ),
            ],
          ),
          const LogOutButton(variant: SolaButtonVariant.warn),
        ],
      ),
    );
  }
}

/// The payout bank's name and last digits, or a nudge to add one.
class _BankLine extends StatelessWidget {
  const new({required this.details});

  final Future<PersonalDetails>? details;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder(
      future: details,
      builder: (context, snapshot) {
        final bank = snapshot.data?.bank;
        return Flexible(
          child: SolaText(
            bank?.last4 == null
                ? l10n.bankNone
                : l10n.bankSub(bank!.bankName ?? '', bank.last4!),
            style: SolaTextStyle.small,
            color: SolaColors.muted,
            textAlign: TextAlign.end,
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const new({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MergeSemantics(
        child: Column(
          spacing: SolaSpace.space2,
          children: [
            SolaText(value, style: SolaTextStyle.sheetTitle),
            SolaText(
              label,
              style: SolaTextStyle.meta,
              color: SolaColors.muted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
