import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/customers/view/customers_tab.dart';
import 'package:solacliq/leads/data/lead_repository.dart';
import 'package:solacliq/leads/view/lead_page.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

void main() {
  final agent = MemberWorkspace(
    testMembership(role: OrgRole.agent, payType: PayType.commission),
  );
  final lead = Lead(
    id: 'l1',
    name: 'Asha Lead',
    phone: '9814022671',
    source: 'Meta ad',
    status: LeadStatus.fresh,
    receivedAt: DateTime(2026, 11, 23, 10),
    city: 'Mohali',
    monthlyBill: '₹3,000 to ₹5,000',
    answers: const {'Roof owner?': 'Yes'},
  );
  late MockLeadRepository leads;
  late MockCustomerRepository customers;

  setUpAll(() => registerFallbackValue(LeadStatus.fresh));

  setUp(() {
    leads = MockLeadRepository();
    when(() => leads.mine(any())).thenAnswer((_) async => [lead]);
    when(() => leads.get(any(), any())).thenAnswer((_) async => lead);
    customers = MockCustomerRepository();
    when(() => customers.mine(any())).thenAnswer((_) async => []);
  });

  Future<void> open(WidgetTester tester, Widget page) async {
    await tester.pumpApp(
      page,
      repositories: [
        RepositoryProvider<LeadRepository>.value(value: leads),
        RepositoryProvider<CustomerRepository>.value(value: customers),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows what the form sent', (tester) async {
    await open(tester, LeadPage(workspace: agent, leadId: 'l1'));
    expect(find.text('Asha Lead'), findsOneWidget);
    expect(find.text('₹3,000 to ₹5,000'), findsOneWidget);
    expect(find.text('Roof owner?'), findsOneWidget);
    expect(find.byKey(const Key('lead_call')), findsOneWidget);
  });

  testWidgets('a status is saved as it is chosen', (tester) async {
    when(() => leads.update(any(), any(), status: any(named: 'status')))
        .thenAnswer((_) async => lead);
    await open(tester, LeadPage(workspace: agent, leadId: 'l1'));
    await tester.tap(find.text('Contacted'));
    await tester.pumpAndSettle();
    verify(() => leads.update(agent.orgId, 'l1', status: LeadStatus.contacted))
        .called(1);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('the note is saved, trimmed', (tester) async {
    when(() => leads.update(any(), any(), note: any(named: 'note')))
        .thenAnswer((_) async => lead);
    await open(tester, LeadPage(workspace: agent, leadId: 'l1'));
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('lead_note')),
        matching: find.byType(EditableText),
      ),
      '  Calls back Monday ',
    );
    await tester.ensureVisible(find.byKey(const Key('lead_save_note')));
    await tester.tap(find.byKey(const Key('lead_save_note')));
    await tester.pumpAndSettle();
    verify(() => leads.update(agent.orgId, 'l1', note: 'Calls back Monday'))
        .called(1);
  });

  testWidgets('open leads lead the customers tab, and open', (tester) async {
    final router = await tester.pumpApp(
      CustomersTab(orgId: agent.orgId),
      repositories: [
        RepositoryProvider<LeadRepository>.value(value: leads),
        RepositoryProvider<CustomerRepository>.value(value: customers),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Leads for you'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lead_row_l1')));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/leads/l1');
  });

  testWidgets('won and lost leads leave the customers tab', (tester) async {
    when(() => leads.mine(any())).thenAnswer(
      (_) async => [
        Lead(
          id: 'l2',
          name: 'Done Lead',
          phone: '9814022671',
          source: 'Meta ad',
          status: LeadStatus.won,
          receivedAt: DateTime(2026, 11, 23),
        ),
      ],
    );
    await open(tester, CustomersTab(orgId: agent.orgId));
    expect(find.text('Leads for you'), findsNothing);
  });
}
