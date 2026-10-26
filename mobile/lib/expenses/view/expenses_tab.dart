import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';
import 'package:solacliq/expenses/view/expense_sent_page.dart';
import 'package:solacliq/l10n/l10n.dart';

/// The worker's expenses: this month's total by status, and the latest.
class ExpensesTab extends StatefulWidget {
  const new({required this.orgId, super.key});

  final String orgId;

  @override
  State<ExpensesTab> createState() => ExpensesTabState();
}

class ExpensesTabState extends State<ExpensesTab> {
  late Future<List<Expense>> _expenses = _fetch();

  Future<List<Expense>> _fetch() =>
      context.read<ExpenseRepository>().mine(widget.orgId);

  /// Reloads, e.g. after logging one.
  Future<void> reload() async {
    final next = _fetch();
    setState(() {
      _expenses = next;
    });
    await next.catchError((Object _) => <Expense>[]);
  }

  Future<void> _push(String path) async {
    await context.push(path);
    if (mounted) await reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RefreshIndicator(
      color: SolaColors.ink,
      onRefresh: reload,
      child: SolaScreen(
        background: SolaBackground.sand,
        bottomOverlaps: true,
        navBar: SolaNavBar(
          title: l10n.tabExpenses,
          trailing: SolaCircleButton(
            key: const Key('expenses_log'),
            icon: SolaIcons.plus,
            semanticsLabel: l10n.logExpense,
            color: SolaColors.sun,
            onPressed: () => unawaited(_push(AppRoutes.expense)),
          ),
        ),
        body: FutureBuilder(
          future: _expenses,
          builder: (context, snapshot) => switch (snapshot) {
            AsyncSnapshot(:final Object error) => Padding(
              padding: const EdgeInsets.only(top: SolaSpace.space26),
              child: SolaNotice(
                title: l10n.expensesLoadFailed,
                body: error is AuthFailure ? error.code.message(l10n) : null,
                action: SolaButton(
                  key: const Key('expenses_retry'),
                  label: l10n.retry,
                  variant: SolaButtonVariant.white,
                  compact: true,
                  expand: false,
                  onPressed: () => unawaited(reload()),
                ),
              ),
            ),
            AsyncSnapshot(data: final items?) => _Content(
              expenses: items,
              onOpen: (e) => unawaited(_push(AppRoutes.expenseDetail(e.id))),
            ),
            _ => const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(
                child: CircularProgressIndicator(color: SolaColors.ink),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const new({required this.expenses, required this.onOpen});

  final List<Expense> expenses;
  final ValueChanged<Expense> onOpen;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final month = [
      for (final e in expenses)
        if (e.spentOn.year == now.year && e.spentOn.month == now.month) e,
    ];
    int sum(bool Function(Expense) test) =>
        month.where(test).fold(0, (total, e) => total + e.amountPaise);
    final total = sum((_) => true);
    final approved = sum(
      (e) =>
          e.status == ExpenseStatus.approved || e.status == ExpenseStatus.paid,
    );
    final review = sum((e) => e.status == ExpenseStatus.inReview);
    final fix = sum((e) => e.status == ExpenseStatus.needsFix);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space12,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: SolaSpace.space4),
          child: SolaHeadline(
            value: formatRupees(total),
            label: _months[now.month - 1],
            detail: l10n.claimCount(month.length),
            style: SolaTextStyle.energy,
          ),
        ),
        if (total > 0)
          SolaProgressCard(
            label: l10n.thisMonth,
            trailing: formatRupees(total),
            barHeight: 8,
            segments: [
              if (approved > 0) SolaSegment(approved, SolaColors.successDot),
              if (review > 0) SolaSegment(review, SolaColors.avatar),
              if (fix > 0) SolaSegment(fix, SolaColors.dangerDot),
            ],
            legend: [
              if (approved > 0)
                SolaLegendItem(
                  l10n.amountApproved(formatRupees(approved)),
                  SolaColors.successDot,
                ),
              if (review > 0)
                SolaLegendItem(
                  l10n.amountReview(formatRupees(review)),
                  SolaColors.avatar,
                ),
              if (fix > 0)
                SolaLegendItem(
                  l10n.amountFix(formatRupees(fix)),
                  SolaColors.dangerDot,
                ),
            ],
          ),
        const SizedBox(height: SolaSpace.space4),
        SolaSectionHeader(l10n.recent),
        if (expenses.isEmpty)
          SolaText(l10n.noExpenses, color: SolaColors.muted)
        else
          SolaGroup(
            children: [
              for (final e in expenses)
                ExpenseRow(expense: e, onTap: () => onOpen(e)),
            ],
          ),
      ],
    );
  }
}
