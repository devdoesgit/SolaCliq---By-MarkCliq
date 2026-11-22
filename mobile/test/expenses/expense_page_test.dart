import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';
import 'package:solacliq/expenses/view/expense_page.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

/// A gallery whose pick is a text file named like a photo.
class _PicksUnreadableFile extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile.fromData(
    Uint8List.fromList('not a picture'.codeUnits),
    path: 'receipt.jpg',
  );
}

void main() {
  late MockExpenseRepository expenses;
  final workspace = MemberWorkspace(testMembership());

  setUpAll(() => registerFallbackValue(ExpenseCategory.fuel));

  setUp(() {
    expenses = MockExpenseRepository();
    when(
      () => expenses.create(
        orgId: any(named: 'orgId'),
        idempotencyKey: any(named: 'idempotencyKey'),
        amountPaise: any(named: 'amountPaise'),
        category: any(named: 'category'),
        note: any(named: 'note'),
        spentOn: any(named: 'spentOn'),
        receiptUploadId: any(named: 'receiptUploadId'),
      ),
    ).thenAnswer(
      (_) async => Expense(
        id: 'e1',
        reference: 'EXP-1',
        amountPaise: 124000,
        category: ExpenseCategory.fuel,
        note: 'Diesel',
        spentOn: DateTime(2026, 10, 23),
        status: ExpenseStatus.inReview,
        hasReceipt: false,
      ),
    );
  });

  Future<void> pump(WidgetTester tester) => tester.pumpApp(
    ExpensePage(workspace: workspace),
    repositories: [
      RepositoryProvider<ExpenseRepository>.value(value: expenses),
      RepositoryProvider<UploadRepository>.value(value: MockUploadRepository()),
    ],
  );

  Future<void> type(WidgetTester tester, String keys) async {
    for (final k in keys.split('')) {
      await tester.tap(find.byKey(ValueKey('keypad_$k')));
      await tester.pump();
    }
  }

  group(ExpensePage, () {
    testWidgets('leaving with nothing typed just goes', (tester) async {
      await pump(tester);
      await tester.tapKey('nav_back');
      await tester.pumpAndSettle();
      expect(find.text('route:/home'), findsOneWidget);
    });

    testWidgets('leaving with an amount asks first', (tester) async {
      await pump(tester);
      await type(tester, '50');
      await tester.tapKey('nav_back');
      await tester.pumpAndSettle();
      expect(find.text('Discard this expense?'), findsOneWidget);
      // Keep editing: still here, amount kept.
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('₹50'), findsOneWidget);
      // Discard: gone.
      await tester.tapKey('nav_back');
      await tester.pumpAndSettle();
      await tester.tapKey('discard_expense');
      await tester.pumpAndSettle();
      expect(find.text('route:/home'), findsOneWidget);
    });

    testWidgets('the keypad types the amount', (tester) async {
      await pump(tester);
      await type(tester, '1240');
      expect(find.text('₹1,240'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('keypad_delete')));
      await tester.pump();
      expect(find.text('₹124'), findsOneWidget);
    });

    testWidgets('asks for the amount, category and note', (tester) async {
      await pump(tester);
      await tester.tapKey('expense_submit');
      await tester.pump();
      expect(find.text('Enter the amount.'), findsOneWidget);
      expect(find.text('Choose one.'), findsOneWidget);
      expect(find.text('Say what it was for.'), findsOneWidget);
      verifyNever(
        () => expenses.create(
          orgId: any(named: 'orgId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          amountPaise: any(named: 'amountPaise'),
          category: any(named: 'category'),
          note: any(named: 'note'),
          spentOn: any(named: 'spentOn'),
        ),
      );
    });

    testWidgets('sends paise to the admin and moves on', (tester) async {
      await pump(tester);
      await type(tester, '1240.5');
      await tester.tapKey('expense_category_0');
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('expense_note')),
          matching: find.byType(TextField),
        ),
        ' Diesel ',
      );
      await tester.tapKey('expense_submit');
      await tester.pumpAndSettle();
      verify(
        () => expenses.create(
          orgId: 'o1',
          idempotencyKey: any(named: 'idempotencyKey'),
          amountPaise: 124050,
          category: ExpenseCategory.fuel,
          note: 'Diesel',
          spentOn: any(named: 'spentOn'),
        ),
      ).called(1);
      expect(find.text('route:/expense/sent'), findsOneWidget);
    });

    testWidgets('a failure is shown and can be sent again', (tester) async {
      when(
        () => expenses.create(
          orgId: any(named: 'orgId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          amountPaise: any(named: 'amountPaise'),
          category: any(named: 'category'),
          note: any(named: 'note'),
          spentOn: any(named: 'spentOn'),
        ),
      ).thenThrow(const AuthFailure(AuthFailureCode.network));
      await pump(tester);
      await type(tester, '5');
      await tester.tapKey('expense_category_1');
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('expense_note')),
          matching: find.byType(TextField),
        ),
        'Cable',
      );
      await tester.tapKey('expense_submit');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('failure_notice')), findsOneWidget);
    });

    testWidgets("the server's reason shows under its field, and goes on edit", (
      tester,
    ) async {
      when(
        () => expenses.create(
          orgId: any(named: 'orgId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          amountPaise: any(named: 'amountPaise'),
          category: any(named: 'category'),
          note: any(named: 'note'),
          spentOn: any(named: 'spentOn'),
        ),
      ).thenThrow(
        const AuthFailure(AuthFailureCode.validation, null, null, {
          'note': 'Up to 200 characters.',
        }),
      );
      await pump(tester);
      await type(tester, '5');
      await tester.tapKey('expense_category_1');
      final note = find.descendant(
        of: find.byKey(const ValueKey('expense_note')),
        matching: find.byType(TextField),
      );
      await tester.enterText(note, 'Cable');
      await tester.tapKey('expense_submit');
      await tester.pumpAndSettle();
      expect(find.text('Up to 200 characters.'), findsOneWidget);
      expect(find.byKey(const Key('failure_notice')), findsOneWidget);

      await tester.enterText(note, 'Cable ties');
      await tester.pumpAndSettle();
      expect(find.text('Up to 200 characters.'), findsNothing);
      expect(find.byKey(const Key('failure_notice')), findsNothing);
    });

    Future<void> refusedWith(
      WidgetTester tester,
      Map<String, String> fields,
    ) async {
      when(
        () => expenses.create(
          orgId: any(named: 'orgId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          amountPaise: any(named: 'amountPaise'),
          category: any(named: 'category'),
          note: any(named: 'note'),
          spentOn: any(named: 'spentOn'),
        ),
      ).thenThrow(AuthFailure(AuthFailureCode.validation, null, null, fields));
      await pump(tester);
      await type(tester, '5');
      await tester.tapKey('expense_category_1');
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('expense_note')),
          matching: find.byType(TextField),
        ),
        'Cable',
      );
      await tester.tapKey('expense_submit');
      await tester.pumpAndSettle();
    }

    for (final (field, message) in [
      ('amount', '₹0.01 to ₹10,00,000.'),
      ('category', 'Not a category.'),
      ('spent_on', 'Within the last year.'),
      ('receipt_upload_id', "The file didn't arrive."),
      ('task_id', 'Not one of your tasks.'),
    ]) {
      testWidgets("the server's $field error is shown", (tester) async {
        await refusedWith(tester, {field: message});
        expect(find.text(message), findsOneWidget);
      });
    }

    testWidgets('a refusal never blocks sending again', (tester) async {
      await refusedWith(tester, {'spent_on': 'Within the last year.'});
      await tester.tapKey('expense_submit');
      await tester.pumpAndSettle();
      verify(
        () => expenses.create(
          orgId: any(named: 'orgId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          amountPaise: any(named: 'amountPaise'),
          category: any(named: 'category'),
          note: any(named: 'note'),
          spentOn: any(named: 'spentOn'),
        ),
      ).called(2);
    });

    testWidgets('changing the category clears the banner', (tester) async {
      await refusedWith(tester, {'category': 'Not a category.'});
      await tester.tapKey('expense_category_2');
      await tester.pumpAndSettle();
      expect(find.text('Not a category.'), findsNothing);
      expect(find.byKey(const Key('failure_notice')), findsNothing);
    });

    testWidgets('changing the date clears its error and the banner', (
      tester,
    ) async {
      await refusedWith(tester, {'spent_on': 'Within the last year.'});
      await tester.tapKey('expense_date');
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Within the last year.'), findsNothing);
      expect(find.byKey(const Key('failure_notice')), findsNothing);
    });

    testWidgets("a receipt that can't be previewed shows as a file", (
      tester,
    ) async {
      ImagePickerPlatform.instance = _PicksUnreadableFile();
      await pump(tester);
      await tester.tapKey('expense_receipt');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick_gallery')));
      await tester.pumpAndSettle();
      // Decoding runs outside the test's fake clock.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('preview_unreadable')), findsOneWidget);
    });

    testWidgets('the note stops at the server limit', (tester) async {
      await pump(tester);
      final note = find.descendant(
        of: find.byKey(const ValueKey('expense_note')),
        matching: find.byType(TextField),
      );
      await tester.enterText(note, 'x' * 250);
      await tester.pump();
      expect(
        tester.widget<TextField>(note).controller!.text,
        hasLength(ExpenseRepository.maxNote),
      );
    });
  });
}
