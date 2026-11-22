import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/home/data/home_repository.dart';
import 'package:solacliq/home/view/home_page.dart';
import 'package:solacliq/install/data/install_repository.dart';
import 'package:solacliq/notifications/data/notification_repository.dart';
import 'package:solacliq/profile/data/profile_repository.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

void main() {
  late MockWorkspaceCubit workspace;
  late MockHomeRepository homes;

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
    when(() => notifications.unreadCount(any())).thenAnswer((_) async => 0);
    workspace = MockWorkspaceCubit();
    homes = MockHomeRepository();
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

    testWidgets('personal: the bell shows a dot for unread ones', (
      tester,
    ) async {
      when(() => notifications.unreadCount(null)).thenAnswer((_) async => 2);
      await pumpHome(tester, const PersonalWorkspace());
      expect(find.bySemanticsLabel('Notifications, new'), findsOneWidget);
    });

    testWidgets('personal: no dot when all are read, or the count fails', (
      tester,
    ) async {
      await pumpHome(tester, const PersonalWorkspace());
      expect(find.bySemanticsLabel('Notifications'), findsOneWidget);

      when(() => notifications.unreadCount(null)).thenAnswer(
        (_) async => throw const AuthFailure(AuthFailureCode.network),
      );
      await pumpHome(tester, const PersonalWorkspace());
      expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
    });

    testWidgets('personal: back from the quote form, the dot is asked again', (
      tester,
    ) async {
      await pumpHome(tester, const PersonalWorkspace());
      verify(() => notifications.unreadCount(null)).called(1);
      await tester.tapKey('home_get_quote');
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.textContaining('route:'))).pop();
      await tester.pumpAndSettle();
      verify(() => notifications.unreadCount(null)).called(1);
    });

    testWidgets('worker: an empty day explains itself, with nothing to see', (
      tester,
    ) async {
      when(() => homes.orgHome(any(), any())).thenAnswer(
        (_) async => const HomeSummary(
          eyebrow: 'Monday, 16 Nov',
          title: "Ravi's day",
          week: [HomeDay(day: 'Mon', date: 16, today: true, dots: [])],
          tiles: [],
          listTitle: 'Up next',
          rows: [
            HomeRow(
              id: 'no_tasks',
              visual: HomeVisual(),
              title: 'Nothing scheduled yet',
              detail: 'Your company assigns your tasks',
            ),
          ],
        ),
      );
      await pumpHome(tester, MemberWorkspace(worker), memberships: [worker]);
      expect(find.text('Nothing scheduled yet'), findsOneWidget);
      expect(find.byKey(const Key('home_see_all')), findsNothing);
      final row = find.byKey(const ValueKey('home_row_no_tasks'));
      expect(
        find.descendant(of: row, matching: find.byType(SolaAvatar)),
        findsNothing,
      );
    });

    testWidgets('worker: rows that open something keep "See all"', (
      tester,
    ) async {
      await pumpHome(tester, MemberWorkspace(worker), memberships: [worker]);
      expect(find.byKey(const Key('home_see_all')), findsOneWidget);
    });

    testWidgets('worker: the server-composed home and worker tabs', (
      tester,
    ) async {
      await pumpHome(tester, MemberWorkspace(worker), memberships: [worker]);
      verify(() => homes.orgHome('o1', OrgRole.worker)).called(1);
      expect(find.text("Ravi's day"), findsOneWidget);
      expect(find.text('Up next'), findsOneWidget);
      expect(find.text('Sample task'), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_upload_proof')), findsNothing);
      expect(find.byKey(const ValueKey('tab_tasks')), findsOneWidget);
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
      when(() => homes.orgHome(any(), any())).thenAnswer(
        (_) async => throw const AuthFailure(AuthFailureCode.network),
      );
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

    testWidgets('a rejected company says so, with nothing to retry', (
      tester,
    ) async {
      final rejected = testMembership(status: OrgStatus.rejected);
      await pumpHome(
        tester,
        MemberWorkspace(rejected),
        memberships: [rejected],
      );
      expect(find.text('Registration not approved'), findsOneWidget);
      expect(find.byKey(const Key('status_check_again')), findsNothing);
      verifyNever(() => homes.orgHome(any(), any()));
    });
  });
}
