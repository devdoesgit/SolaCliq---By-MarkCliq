import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/home/data/home_repository.dart';
import 'package:solacliq/home/view/home_page.dart';
import 'package:solacliq/install/data/install_repository.dart';
import 'package:solacliq/invites/data/invite_repository.dart';
import 'package:solacliq/notifications/data/notification_repository.dart';
import 'package:solacliq/profile/data/profile_repository.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

void main() {
  late MockWorkspaceCubit workspace;
  late MockHomeRepository homes;
  late MockInviteRepository invites;

  final worker = testMembership();
  final agent = testMembership(orgId: 'o2', role: OrgRole.agent);
  final customer = testMembership(orgId: 'o3', role: OrgRole.customer);

  const workerHome = HomeSummary(
    eyebrow: 'Thursday, 23 Oct',
    title: "Ravi's day",
    headline: HomeHeadline(value: '3', label: 'tasks', detail: 'on site'),
    week: [
      HomeDay(day: 'Thu', date: 23, today: true, dots: [HomeDot.live]),
    ],
    tiles: [
      HomeTile(label: 'Proof due', value: '2', dark: true, action: 'proof'),
      HomeTile(label: 'Expenses', value: '1', action: 'expenses'),
    ],
    listTitle: 'Up next',
    rows: [
      HomeRow(
        id: 't1',
        visual: HomeVisual(image: 'asset:thumb-install'),
        title: 'Sample task',
        detail: '5 kW',
        status: HomeStatus(label: 'Proof due', tone: HomeTone.warning),
        action: 'task',
      ),
    ],
  );

  late MockCustomerRepository customers;
  late MockInstallRepository installs;
  late MockNotificationRepository notifications;
  late MockProfileRepository profiles;

  setUp(() {
    customers = MockCustomerRepository();
    when(() => customers.mine(any())).thenAnswer((_) async => []);
    installs = MockInstallRepository();
    when(() => installs.mine(any())).thenAnswer(
      (_) async => const Install(
        systemKw: 5,
        place: 'Mohali',
        stageIndex: 1,
        stageCount: 7,
        totalPaise: 28500000,
        subsidyPaise: 7800000,
        stages: [],
        payments: [],
      ),
    );
    profiles = MockProfileRepository();
    when(() => profiles.details())
        .thenAnswer((_) async => const PersonalDetails());
    notifications = MockNotificationRepository();
    when(() => notifications.list(any())).thenAnswer((_) async => []);
    workspace = MockWorkspaceCubit();
    homes = MockHomeRepository();
    invites = MockInviteRepository();
    when(() => invites.pending()).thenAnswer((_) async => []);
    when(() => homes.orgHome(any(), any())).thenAnswer((_) async => workerHome);
  });

  setUpAll(() => registerFallbackValue(OrgRole.worker));

  Future<void> pumpHome(
    WidgetTester tester,
    Workspace current, {
    List<AccountMembership> memberships = const [],
  }) async {
    final options = [
      for (final m in memberships) MemberWorkspace(m),
      const PersonalWorkspace(),
    ];
    when(() => workspace.state).thenReturn(
      WorkspaceReady(testAccount(memberships: memberships), current, options),
    );
    await tester.pumpApp(
      const HomePage(),
      workspaceCubit: workspace,
      repositories: [
        RepositoryProvider<HomeRepository>.value(value: homes),
        RepositoryProvider<InviteRepository>.value(value: invites),
        RepositoryProvider<CustomerRepository>.value(value: customers),
        RepositoryProvider<InstallRepository>.value(value: installs),
        RepositoryProvider<ProfileRepository>.value(value: profiles),
        RepositoryProvider<NotificationRepository>.value(value: notifications),
      ],
    );
    await tester.pumpAndSettle();
  }

  group(HomePage, () {
    testWidgets('personal: subsidy, quote card and its tabs', (tester) async {
      await pumpHome(tester, const PersonalWorkspace());
      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('₹78k'), findsOneWidget);
      expect(find.byKey(const Key('home_get_quote')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_get_quote')), findsOneWidget);
    });

    testWidgets('personal: an invite shows a banner to review', (tester) async {
      when(() => invites.pending()).thenAnswer(
        (_) async => [
          Invite(
            id: 'i1',
            orgId: 'o1',
            orgName: 'Example Solar',
            role: OrgRole.worker,
            invitedBy: 'Dev',
            invitedAt: DateTime(2026, 10, 20),
          ),
        ],
      );
      await pumpHome(tester, const PersonalWorkspace());
      expect(find.text('Example Solar invited you'), findsOneWidget);
      expect(find.byKey(const ValueKey('invite_review_i1')), findsOneWidget);
    });

    testWidgets('worker: the server-composed home and worker tabs', (
      tester,
    ) async {
      await pumpHome(tester, MemberWorkspace(worker), memberships: [worker]);
      verify(() => homes.orgHome('o1', OrgRole.worker)).called(1);
      expect(find.text("Ravi's day"), findsOneWidget);
      expect(find.text('Up next'), findsOneWidget);
      expect(find.text('Sample task'), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_upload_proof')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_expenses')), findsOneWidget);
    });

    testWidgets('worker: the expenses tile opens the expenses tab', (
      tester,
    ) async {
      await pumpHome(tester, MemberWorkspace(worker), memberships: [worker]);
      await tester.tapKey('home_tile_1');
      await tester.pumpAndSettle();
      expect(find.text('No expenses yet.'), findsOneWidget);
    });

    testWidgets('worker: a row opens its task', (tester) async {
      await pumpHome(tester, MemberWorkspace(worker), memberships: [worker]);
      await tester.tapKey('home_row_t1');
      await tester.pumpAndSettle();
      expect(find.text('route:/tasks/t1'), findsOneWidget);
    });

    testWidgets('agent: the raised tab adds a customer', (tester) async {
      await pumpHome(tester, MemberWorkspace(agent), memberships: [agent]);
      await tester.tap(find.byKey(const ValueKey('tab_add_customer')));
      await tester.pumpAndSettle();
      expect(find.text('route:/customers/new'), findsOneWidget);
    });

    testWidgets('customer: track and payments tabs', (tester) async {
      await pumpHome(
        tester,
        MemberWorkspace(customer),
        memberships: [customer],
      );
      expect(find.byKey(const ValueKey('tab_track')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_payments')), findsOneWidget);
    });

    testWidgets('a failed load offers a retry', (tester) async {
      when(() => homes.orgHome(any(), any()))
          .thenThrow(const AuthFailure(AuthFailureCode.network));
      await pumpHome(tester, MemberWorkspace(worker), memberships: [worker]);
      expect(find.byKey(const Key('home_retry')), findsOneWidget);
    });

    testWidgets('a suspended company shows its status, no tabs', (
      tester,
    ) async {
      final suspended = testMembership(status: OrgStatus.suspended);
      await pumpHome(
        tester,
        MemberWorkspace(suspended),
        memberships: [suspended],
      );
      expect(find.byKey(const Key('status_check_again')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_home')), findsNothing);
      verifyNever(() => homes.orgHome(any(), any()));
    });
  });
}
