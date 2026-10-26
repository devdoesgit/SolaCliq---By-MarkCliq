import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// What [ExpenseSentPage] shows, passed by the expense form.
class ExpenseSentArgs {
  const new({required this.workspace, required this.expense});

  final MemberWorkspace workspace;
  final Expense expense;
}

/// The expense is with the admin: its reference, and the person's recent
/// expenses with their status.
class ExpenseSentPage extends StatefulWidget {
  const new({required this.args, super.key});

  final ExpenseSentArgs args;

  @override
  State<ExpenseSentPage> createState() => _ExpenseSentPageState();
}

class _ExpenseSentPageState extends State<ExpenseSentPage> {
  late final Future<List<Expense>> _recent = context
      .read<ExpenseRepository>()
      .mine(widget.args.workspace.orgId);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expense = widget.args.expense;
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
            title: l10n.sentToAdmin,
            body: l10n.expenseSentBody,
            pill: SolaPill(
              l10n.expenseRef(
                expense.reference,
                formatRupees(expense.amountPaise),
              ),
              icon: SolaIcons.hourglass,
            ),
          ),
          const SizedBox(height: SolaSpace.space22),
          FutureBuilder(
            future: _recent,
            builder: (context, snapshot) {
              final items = snapshot.data;
              // The list is a bonus; the expense is sent either way.
              if (items == null || items.isEmpty) return const SizedBox();
              return SolaGroup(
                children: [
                  for (final e in items.take(5)) ExpenseRow(expense: e),
                ],
              );
            },
          ),
        ],
      ),
      bottom: SolaBottomBar(
        children: [
          SolaButton(
            key: const Key('expense_sent_home'),
            label: l10n.backToHome,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}

/// One expense: category and amount, when and what for, and its status.
class ExpenseRow extends StatelessWidget {
  const new({required this.expense, this.onTap, super.key});

  final Expense expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final e = expense;
    final days = DateUtils.dateOnly(DateTime.now())
        .difference(DateUtils.dateOnly(e.spentOn))
        .inDays;
    final day = days == 0
        ? l10n.todayTitle
        : days < 7
        ? formatWeekday(e.spentOn)
        : formatDayMonth(e.spentOn);
    final what = e.taskCustomer != null
        ? l10n.customerSite(e.taskCustomer!)
        : e.note;
    return SolaListRow(
      key: ValueKey('expense_${e.id}'),
      title: l10n.expenseRowTitle(
        e.category.label(l10n),
        formatRupees(e.amountPaise),
      ),
      subtitle: '$day · $what',
      leading: const SolaThumb(glyph: SolaGlyph.rupee),
      trailing: e.status.pill(l10n),
      onTap: onTap,
    );
  }
}

extension ExpenseCategoryText on ExpenseCategory {
  String label(AppLocalizations l10n) => switch (this) {
    ExpenseCategory.fuel => l10n.categoryFuel,
    ExpenseCategory.material => l10n.categoryMaterial,
    ExpenseCategory.labour => l10n.categoryLabour,
    ExpenseCategory.other => l10n.categoryOther,
  };
}

extension ExpenseStatusText on ExpenseStatus {
  SolaPill pill(AppLocalizations l10n) => switch (this) {
    ExpenseStatus.inReview => SolaPill(l10n.statusInReview),
    ExpenseStatus.approved => SolaPill(
      l10n.statusApproved,
      tone: SolaTone.success,
      icon: SolaIcons.check,
    ),
    ExpenseStatus.paid => SolaPill(
      l10n.statusPaid,
      tone: SolaTone.success,
      icon: SolaIcons.check,
    ),
    ExpenseStatus.needsFix => SolaPill(
      l10n.statusNeedsFix,
      tone: SolaTone.danger,
      icon: SolaIcons.alarm,
    ),
  };
}
