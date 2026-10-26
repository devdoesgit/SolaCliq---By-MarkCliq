import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/customers/view/customer_text.dart';
import 'package:solacliq/customers/view/customers_tab.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/view/task_text.dart';

/// A commission agent's earnings, summed from their customers: paid this
/// month, what is still in the pipeline, and each commission.
class EarningsTab extends StatefulWidget {
  const new({required this.orgId, super.key});

  final String orgId;

  @override
  State<EarningsTab> createState() => EarningsTabState();
}

class EarningsTabState extends State<EarningsTab> {
  late Future<List<CustomerSummary>> _customers = _fetch();

  Future<List<CustomerSummary>> _fetch() =>
      context.read<CustomerRepository>().mine(widget.orgId);

  void reload() => setState(() => _customers = _fetch());

  Future<void> _open(CustomerSummary c) async {
    await context.push(AppRoutes.customer(c.id));
    if (mounted) reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SolaScreen(
      background: SolaBackground.stone,
      bottomOverlaps: true,
      navBar: SolaNavBar(title: l10n.tabEarnings),
      body: LoadView(
        future: _customers,
        failedTitle: l10n.customersLoadFailed,
        onRetry: reload,
        builder: (context, all) {
          final withCommission = [
            for (final c in all)
              if (c.commission != null) c,
          ];
          if (withCommission.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: SolaSpace.space26),
              child: SolaText(
                l10n.noCommissions,
                color: SolaColors.muted,
                textAlign: TextAlign.center,
              ),
            );
          }
          final now = DateTime.now();
          int sum(bool Function(Commission) test) => withCommission
              .map((c) => c.commission!)
              .where(test)
              .fold(0, (total, c) => total + c.amountPaise);
          final paidNow = withCommission.where((c) {
            final paidOn = c.commission!.paidOn;
            return c.commission!.status == CommissionStatus.paid &&
                paidOn != null &&
                paidOn.year == now.year &&
                paidOn.month == now.month;
          }).toList();
          final paid = paidNow.fold(
            0,
            (total, c) => total + c.commission!.amountPaise,
          );
          final payable = sum((c) => c.status == CommissionStatus.payable);
          final waiting = sum((c) => c.status == CommissionStatus.approved);
          final review = sum((c) => c.status == CommissionStatus.inReview);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SolaSpace.space14,
            children: [
              SolaHeadline(
                value: formatRupees(paid),
                label: l10n.paidThisMonth,
                detail: l10n.paidMonthLine(
                  DateFormat.MMMM().format(now),
                  paidNow.length,
                ),
              ),
              SolaProgressCard(
                label: l10n.inThePipeline,
                trailing: formatRupees(payable + waiting + review),
                segments: [
                  SolaSegment(payable, SolaColors.sun),
                  SolaSegment(waiting, SolaColors.success),
                  SolaSegment(review, SolaColors.track),
                ],
                legend: [
                  SolaLegendItem(
                    l10n.legendPayable(formatRupees(payable)),
                    SolaColors.sun,
                  ),
                  SolaLegendItem(
                    l10n.legendWaiting(formatRupees(waiting)),
                    SolaColors.success,
                  ),
                  SolaLegendItem(
                    l10n.legendReview(formatRupees(review)),
                    SolaColors.track,
                  ),
                ],
              ),
              SolaSectionLabel(l10n.commissionsTitle),
              CustomerGroup(
                customers: withCommission,
                onOpen: (c) => unawaited(_open(c)),
                trailing: (c) => c.commission!.status.pill(l10n),
                subtitle: (c) => _line(l10n, c),
                title: (c) => l10n.nameAmount(
                  firstName(c.name),
                  formatRupees(c.commission!.amountPaise),
                ),
              ),
              SolaText(
                l10n.earningsFooter,
                style: SolaTextStyle.small,
                color: SolaColors.muted,
              ),
            ],
          );
        },
      ),
    );
  }

  static String _line(AppLocalizations l10n, CustomerSummary c) {
    final commission = c.commission!;
    return switch (commission.status) {
      CommissionStatus.payable => l10n.advancePaid(
        formatDayMonth(commission.payableSince ?? c.sentAt),
      ),
      CommissionStatus.approved => l10n.waitsForAdvance,
      CommissionStatus.inReview => l10n.sentWhen(formatAgo(c.sentAt)),
      CommissionStatus.paid => l10n.advancePaid(
        formatDayMonth(commission.paidOn ?? c.sentAt),
      ),
    };
  }
}
