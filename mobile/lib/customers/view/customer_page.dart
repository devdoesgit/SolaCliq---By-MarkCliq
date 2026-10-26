import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/customers/view/customer_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/view/task_text.dart';
import 'package:solacliq/workspace/data/workspace.dart';
import 'package:url_launcher/url_launcher.dart';

/// One customer a Sales person added: their KYC, install progress and,
/// for commission agents, the commission. A returned document can be
/// sent again from here.
class CustomerPage extends StatefulWidget {
  const new({required this.workspace, required this.customerId, super.key});

  final MemberWorkspace workspace;
  final String customerId;

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  late Future<CustomerDetail> _customer = _fetch();

  Future<CustomerDetail> _fetch() => context.read<CustomerRepository>().get(
    widget.workspace.orgId,
    widget.customerId,
  );

  void _reload() => setState(() => _customer = _fetch());

  Future<void> _fix() async {
    await context.push(AppRoutes.customerFix(widget.customerId));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder(
      future: _customer,
      builder: (context, snapshot) {
        final c = snapshot.data;
        return SolaScreen(
          background: SolaBackground.stone,
          navBar: SolaNavBar(
            leading: const BackTo(fallback: AppRoutes.home),
            title: l10n.customerTitle,
            trailing: c == null
                ? null
                : SolaCircleButton(
                    key: const Key('customer_call'),
                    icon: SolaIcons.phone,
                    semanticsLabel: l10n.callPerson(c.summary.name),
                    onPressed: () =>
                        unawaited(launchUrl(Uri.parse('tel:+91${c.phone}'))),
                  ),
          ),
          body: LoadView(
            future: _customer,
            failedTitle: l10n.customerLoadFailed,
            onRetry: _reload,
            builder: (context, c) => _Details(
              customer: c,
              earnsCommission: widget.workspace.earnsCommission,
            ),
          ),
          bottom: c?.returned == null
              ? null
              : SolaBottomBar(
                  children: [
                    SolaButton(
                      key: const Key('customer_fix'),
                      label: l10n.uploadNew(
                        c!.returned!.kind.label(l10n).toLowerCase(),
                      ),
                      icon: SolaIcons.camera,
                      onPressed: () => unawaited(_fix()),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Details extends StatelessWidget {
  const new({required this.customer, required this.earnsCommission});

  final CustomerDetail customer;
  final bool earnsCommission;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = customer;
    final s = c.summary;
    final returned = c.returned;
    final commission = earnsCommission ? s.commission : null;
    final index = c.stageIndex ?? 0;
    final count = c.stageCount ?? 7;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        MergeSemantics(
          child: Column(
            spacing: SolaSpace.space8,
            children: [
              SolaAvatar(initials: s.initials, size: 64),
              SolaText(s.name, style: SolaTextStyle.titleSm),
              SolaText(s.place2(l10n), color: SolaColors.muted),
              s.kyc.pill(l10n),
            ],
          ),
        ),
        SolaProgressCard(
          label: c.stageIndex == null
              ? l10n.installProgress
              : l10n.stageXofY(index, count),
          trailing: c.stageLabel ?? l10n.startsAfterKyc,
          segments: [
            for (var i = 1; i <= count; i++)
              SolaSegment(1, i <= index ? SolaColors.sun : SolaColors.track),
          ],
        ),
        if (returned != null)
          SolaBanner(
            title: l10n.docReturned(returned.title.toLowerCase()),
            body: returned.note.text,
            tone: SolaTone.danger,
            icon: SolaIcons.alert,
            personInitials: initialsOf(returned.note.by),
            personLabel: returned.note.by,
          )
        else if (s.kyc == KycStatus.inReview)
          SolaBanner(
            title: l10n.withAdmin,
            body: l10n.withAdminSent(formatWhen(s.sentAt)),
            icon: SolaIcons.hourglass,
          ),
        if (c.documentsDetail != null || c.advancePaidOn != null)
          SolaGroup(
            children: [
              if (c.documentsDetail case final docs?)
                SolaListRow(
                  title: l10n.documentsLabel,
                  subtitle: docs,
                  leading: const SolaAvatar(
                    icon: SolaIcons.file,
                    color: SolaColors.tan,
                  ),
                  trailing: c.documentsVerified == true
                      ? SolaPill(l10n.verified, tone: SolaTone.success)
                      : SolaPill(l10n.statusInReview),
                ),
              SolaListRow(
                title: l10n.advanceLabel,
                subtitle: c.advancePaidOn == null
                    ? l10n.advanceDue
                    : l10n.advancePaid(formatDayMonth(c.advancePaidOn!)),
                leading: const SolaAvatar(
                  icon: SolaIcons.wallet,
                  color: SolaColors.tan,
                ),
                trailing: c.advancePaidOn == null
                    ? null
                    : SolaPill(l10n.statusPaid, tone: SolaTone.success),
              ),
            ],
          ),
        if (commission != null)
          _CommissionCard(
            commission: commission,
            customerFirstName: firstName(s.name),
            waitingForFix: s.kyc == KycStatus.needsFix,
          ),
      ],
    );
  }
}

class _CommissionCard extends StatelessWidget {
  const new({
    required this.commission,
    required this.customerFirstName,
    required this.waitingForFix,
  });

  final Commission commission;
  final String customerFirstName;
  final bool waitingForFix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = commission;
    final note = c.adminNote;
    return SolaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SolaSpace.space10,
        children: [
          Row(
            children: [
              Expanded(
                child: SolaText(
                  l10n.yourCommission,
                  style: SolaTextStyle.eyebrow,
                  color: SolaColors.muted,
                ),
              ),
              c.status.pill(l10n),
            ],
          ),
          SolaText(formatRupees(c.amountPaise), style: SolaTextStyle.amount),
          if (c.proposedPaise case final asked?)
            SolaText(
              l10n.commissionAsked(formatRupees(asked)),
              style: SolaTextStyle.small,
              color: SolaColors.muted,
            ),
          if (note != null)
            SolaBanner(
              title: l10n.changedByAdmin,
              body: note.text,
              icon: SolaIcons.alert,
              tone: SolaTone.warning,
              personInitials: initialsOf(note.by),
              personLabel: note.by,
            ),
          SolaText(
            switch (c.status) {
              CommissionStatus.paid => l10n.commissionPaidBody(
                formatDayMonth(c.paidOn ?? DateTime.now()),
              ),
              CommissionStatus.payable => l10n.commissionPayableBody(
                formatDayMonth(c.payableSince ?? DateTime.now()),
              ),
              _ when waitingForFix => l10n.commissionAfterFix,
              _ => l10n.commissionWaits(customerFirstName),
            },
            style: SolaTextStyle.small,
            color: SolaColors.muted,
          ),
        ],
      ),
    );
  }
}
