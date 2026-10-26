import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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
  final workspace = MemberWorkspace(testMembership(role: OrgRole.agent));

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

    testWidgets('cancel leaves the flow', (tester) async {
      await pump(tester);
      await tester.tapKey('add_customer_cancel');
      await tester.pumpAndSettle();
      expect(find.text('route:/home'), findsOneWidget);
    });
  });
}
