import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/customers/view/add_customer_page.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

Finder _input(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

void main() {
  final workspace = MemberWorkspace(
    testMembership(role: OrgRole.agent, payType: PayType.commission),
  );

  Future<void> pump(WidgetTester tester) => tester.pumpApp(
    AddCustomerPage(workspace: workspace),
    repositories: [
      RepositoryProvider<UploadRepository>.value(value: MockUploadRepository()),
      RepositoryProvider<RegistrationRepository>.value(
        value: MockRegistrationRepository(),
      ),
    ],
  );

  Future<void> pick(WidgetTester tester, String row, String option) async {
    await tester.tapKey(row);
    await tester.pumpAndSettle();
    await tester.tapKey('option_$option');
    await tester.pumpAndSettle();
  }

  group(AddCustomerPage, () {
    testWidgets('checks each step before moving on', (tester) async {
      await pump(tester);
      expect(find.text('Step 1 of 3'), findsOneWidget);
      await tester.tapKey('add_customer_next');
      await tester.pump();
      expect(find.text('Enter the city and the 6-digit PIN.'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
    });

    testWidgets('details then site, with back keeping what was typed', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(_input('customer_name'), 'Test Customer');
      await tester.enterText(_input('customer_mobile'), '98140 22671');
      await tester.enterText(_input('customer_email'), 't@example.com');
      await tester.enterText(_input('customer_address'), 'H 1');
      await tester.enterText(_input('customer_city_pin'), 'Mohali 160062');
      await pick(tester, 'customer_state', 'Punjab');
      await tester.tapKey('add_customer_next');
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 3'), findsOneWidget);
      // Punjab has one provider, so it is already chosen.
      expect(find.text('PSPCL · Punjab'), findsOneWidget);

      await tester.tapKey('nav_back');
      await tester.pumpAndSettle();
      expect(find.text('Test Customer'), findsOneWidget);
    });

    group('what is sent', () {
      setUpAll(
        () => registerFallbackValue(
          const CustomerDraft(
            name: '',
            phone: '',
            email: '',
            address: '',
            city: '',
            pinCode: '',
            state: '',
            discom: '',
            consumerNumber: '',
            sanctionedLoadKw: 0,
            connectionType: ConnectionType.residential,
            proposedKw: 0,
            roof: Roof.rcc,
            subsidy: false,
            documents: {},
            consent: true,
          ),
        ),
      );

      /// Walks the whole flow with quick forms filling every step, types
      /// [commission] and [note] on the review step when the fields are
      /// there, submits, and returns the draft sent.
      Future<CustomerDraft> submitAs(
        WidgetTester tester,
        PayType payType, {
        String commission = '',
        String note = '',
      }) async {
        final registrations = MockRegistrationRepository();
        when(
          () => registrations.submit(
            orgId: any(named: 'orgId'),
            idempotencyKey: any(named: 'idempotencyKey'),
            draft: any(named: 'draft'),
          ),
        ).thenAnswer((_) async => 'SC-1');
        await tester.pumpApp(
          AddCustomerPage(
            workspace: MemberWorkspace(
              testMembership(role: OrgRole.agent, payType: payType),
            ),
          ),
          repositories: [
            RepositoryProvider<UploadRepository>.value(
              value: MockUploadRepository(),
            ),
            RepositoryProvider<RegistrationRepository>.value(
              value: registrations,
            ),
            RepositoryProvider<QuickForms>(
              create: (_) => QuickForms(available: true),
              dispose: (quick) => quick.dispose(),
            ),
          ],
        );
        for (final key in ['add_customer_next', 'add_customer_next']) {
          await tester.tapKey(key);
          await tester.pumpAndSettle();
        }
        await tester.tapKey('add_customer_review');
        await tester.pumpAndSettle();
        final fields = find.byKey(const ValueKey('add_customer_commission'));
        if (fields.evaluate().isNotEmpty) {
          await tester.enterText(_input('add_customer_commission'), commission);
          await tester.enterText(_input('add_customer_commission_note'), note);
        }
        await tester.tapKey('add_customer_submit');
        await tester.pumpAndSettle();
        return verify(
              () => registrations.submit(
                orgId: 'o1',
                idempotencyKey: any(named: 'idempotencyKey'),
                draft: captureAny(named: 'draft'),
              ),
            ).captured.single
            as CustomerDraft;
      }

      testWidgets('commission agents send their commission in paise', (
        tester,
      ) async {
        final draft = await submitAs(
          tester,
          PayType.commission,
          commission: '5000',
          note: '1,000 per kW',
        );
        expect(draft.commissionPaise, 500000);
        expect(draft.commissionNote, '1,000 per kW');
      });

      testWidgets('salaried sales see no commission step and send none', (
        tester,
      ) async {
        final draft = await submitAs(tester, PayType.salary);
        expect(
          find.byKey(const ValueKey('add_customer_commission')),
          findsNothing,
        );
        expect(draft.commissionPaise, isNull);
        expect(draft.commissionNote, isNull);
      });
    });

    testWidgets('cancel leaves the flow', (tester) async {
      await pump(tester);
      await tester.tapKey('add_customer_cancel');
      await tester.pumpAndSettle();
      expect(find.text('route:/home'), findsOneWidget);
    });

    testWidgets('leaving with a draft asks first', (tester) async {
      await pump(tester);
      await tester.enterText(_input('customer_name'), 'Test Customer');
      await tester.tapKey('add_customer_cancel');
      await tester.pumpAndSettle();
      expect(find.text('Discard this customer?'), findsOneWidget);

      // Keep editing: still on the form, nothing lost.
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Test Customer'), findsOneWidget);

      // The system Back button asks too.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard this customer?'), findsOneWidget);
      await tester.tapKey('discard_customer');
      await tester.pumpAndSettle();
      expect(find.text('route:/home'), findsOneWidget);
    });
  });
}
