import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/install/data/install_repository.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/workspace/data/workspace.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// A customer's payments: the system's price, what is due now, the plan
/// and the subsidy. The due payment is paid by UPI or bank transfer, then
/// claimed for the company to confirm.
class PaymentsTab extends StatefulWidget {
  const new({required this.workspace, super.key});

  final MemberWorkspace workspace;

  @override
  State<PaymentsTab> createState() => PaymentsTabState();
}

class PaymentsTabState extends State<PaymentsTab> {
  late Future<Install> _install = _fetch();
  bool _sending = false;
  String? _error;

  /// One per claim, so a retry never claims twice.
  String _idempotencyKey = const Uuid().v4();

  Future<Install> _fetch() =>
      context.read<InstallRepository>().mine(widget.workspace.orgId);

  void reload() => setState(() => _install = _fetch());

  Future<void> _pay(Install install, PaymentMethod method) async {
    final due = install.due;
    if (due == null) return;
    final l10n = context.l10n;
    if (method == PaymentMethod.upi) {
      final uri = install.upiUri;
      final opened =
          uri != null &&
          await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
      if (!opened) {
        if (mounted) setState(() => _error = l10n.noUpiApp);
        return;
      }
    }
    if (!mounted) return;
    final repo = context.read<InstallRepository>();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final updated = await repo.claim(
        orgId: widget.workspace.orgId,
        paymentId: due.id,
        method: method,
        idempotencyKey: _idempotencyKey,
      );
      _idempotencyKey = const Uuid().v4();
      if (mounted) setState(() => _install = Future.value(updated));
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.code.message(l10n));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final org = widget.workspace.orgName;
    return Builder(
      builder: (context) {
        return SolaScreen(
          background: SolaBackground.sky,
          bottomOverlaps: true,
          navBar: SolaNavBar(title: l10n.paymentsTitle),
          body: LoadView(
            future: _install,
            failedTitle: l10n.installLoadFailed,
            onRetry: reload,
            builder: (context, install) => _Plan(
              install: install,
              org: org,
              error: _error,
              actions: [
                if (install.due case final due?) ...[
                  SolaButton(
                    key: const Key('pay_upi'),
                    label: l10n.payByUpi(formatRupees(due.amountPaise)),
                    onPressed: _sending
                        ? null
                        : () => unawaited(_pay(install, PaymentMethod.upi)),
                  ),
                  SolaButton(
                    key: const Key('pay_bank'),
                    label: l10n.paidByBank,
                    variant: SolaButtonVariant.white,
                    onPressed: _sending
                        ? null
                        : () => unawaited(
                            _pay(install, PaymentMethod.bankTransfer),
                          ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Plan extends StatelessWidget {
  const new({
    required this.install,
    required this.org,
    required this.actions,
    this.error,
  });

  final Install install;
  final String org;
  final List<Widget> actions;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final due = install.due;
    final claimed = install.payments
        .where((p) => p.status == PaymentStatus.claimed)
        .firstOrNull;
    final error = this.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SolaSpace.space2,
            children: [
              SolaText(
                formatRupees(install.totalPaise),
                style: SolaTextStyle.amount,
              ),
              SolaText(
                l10n.totalLine('${install.systemKw}'),
                color: SolaColors.muted,
              ),
            ],
          ),
        ),
        if (due != null)
          SolaCard(
            color: SolaColors.brown,
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SolaSpace.space8,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SolaText(
                          l10n.advanceDueTitle(due.label.split(',').first),
                          style: SolaTextStyle.eyebrow,
                          color: SolaColors.cream,
                        ),
                      ),
                      if (due.detail case final detail?)
                        SolaPill(detail, tone: SolaTone.warning),
                    ],
                  ),
                  SolaText(
                    formatRupees(due.amountPaise),
                    style: SolaTextStyle.amount,
                    color: SolaColors.cream,
                  ),
                  SolaText(
                    l10n.bookedOnceReceived(org),
                    style: SolaTextStyle.small,
                    color: SolaColors.onBrownMuted,
                  ),
                ],
              ),
            ),
          ),
        if (claimed != null)
          SolaBanner(
            title: l10n.paymentClaimedTitle,
            body: l10n.paymentClaimedBody(org),
            tone: SolaTone.success,
            icon: SolaIcons.check,
          ),
        if (error != null)
          SolaNotice(
            key: const Key('failure_notice'),
            title: error,
            announce: true,
          ),
        SolaSectionLabel(l10n.paymentPlan),
        SolaGroup(
          children: [
            for (final p in install.payments)
              SolaListRow(
                key: ValueKey('payment_${p.id}'),
                title: p.label,
                subtitle: p.detail,
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: SolaSpace.space4,
                  children: [
                    SolaText(
                      formatRupees(p.amountPaise),
                      style: SolaTextStyle.rowTitle,
                    ),
                    ?switch (p.status) {
                      PaymentStatus.due => SolaPill(
                        l10n.statusDue,
                        tone: SolaTone.warning,
                      ),
                      PaymentStatus.claimed => SolaPill(l10n.statusClaimed),
                      PaymentStatus.paid => SolaPill(
                        l10n.statusPaid,
                        tone: SolaTone.success,
                      ),
                      PaymentStatus.later => null,
                    },
                  ],
                ),
              ),
            SolaListRow(
              title: l10n.subsidyRow,
              subtitle: l10n.subsidyRowSub,
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: SolaSpace.space4,
                children: [
                  SolaText(
                    formatRupees(install.subsidyPaise),
                    style: SolaTextStyle.rowTitle,
                  ),
                  SolaPill(l10n.backToYou, tone: SolaTone.success),
                ],
              ),
            ),
          ],
        ),
        ...actions,
      ],
    );
  }
}
