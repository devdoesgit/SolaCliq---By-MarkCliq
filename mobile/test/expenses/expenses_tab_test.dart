import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';
import 'package:solacliq/expenses/view/expenses_tab.dart';

import '../helpers/helpers.dart';

void main() {
  late MockExpenseRepository expenses;

  setUp(() {
    expenses = MockExpenseRepository();
    when(() => expenses.mine(any())).thenAnswer(
      (_) async => [
        Expense(
          id: 'e1',
          reference: 'EXP-1',
          amountPaise: 45000,
          category: ExpenseCategory.values.first,
          note: 'Diesel for the van',
          spentOn: DateTime(2026, 10, 22),
          status: ExpenseStatus.values.first,
          hasReceipt: true,
        ),
      ],
    );
  });

  group(ExpensesTab, () {
    testWidgets('lists the expenses and opens one', (tester) async {
      await tester.pumpApp(
        const ExpensesTab(orgId: 'o1'),
        repositories: [
          RepositoryProvider<ExpenseRepository>.value(value: expenses),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Diesel for the van'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('expense_e1')));
      await tester.pumpAndSettle();
      expect(find.text('route:/expenses/e1'), findsOneWidget);
    });

    testWidgets('logs a new one', (tester) async {
      await tester.pumpApp(
        const ExpensesTab(orgId: 'o1'),
        repositories: [
          RepositoryProvider<ExpenseRepository>.value(value: expenses),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expenses_log')));
      await tester.pumpAndSettle();
      expect(find.textContaining('route:/expense'), findsOneWidget);
    });
  });
}
