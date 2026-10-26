import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/access/view/request_access_page.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/intro_page.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/customers/view/add_customer_page.dart';
import 'package:solacliq/customers/view/customer_page.dart';
import 'package:solacliq/customers/view/customers_tab.dart';
import 'package:solacliq/customers/view/earnings_tab.dart';
import 'package:solacliq/customers/view/fix_document_page.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';
import 'package:solacliq/expenses/view/expense_detail_page.dart';
import 'package:solacliq/expenses/view/expense_page.dart';
import 'package:solacliq/expenses/view/expenses_tab.dart';
import 'package:solacliq/home/data/home_repository.dart';
import 'package:solacliq/home/view/home_page.dart';
import 'package:solacliq/install/data/install_repository.dart';
import 'package:solacliq/install/view/payments_tab.dart';
import 'package:solacliq/install/view/track_tab.dart';
import 'package:solacliq/invites/data/invite_repository.dart';
import 'package:solacliq/invites/view/invite_page.dart';
import 'package:solacliq/learn/view/learn_page.dart';
import 'package:solacliq/notifications/data/notification_repository.dart';
import 'package:solacliq/notifications/view/notifications_page.dart';
import 'package:solacliq/profile/data/profile_repository.dart';
import 'package:solacliq/profile/view/bank_page.dart';
import 'package:solacliq/profile/view/details_page.dart';
import 'package:solacliq/profile/view/documents_page.dart';
import 'package:solacliq/profile/view/profile_tab.dart';
import 'package:solacliq/profile/view/settings_page.dart';
import 'package:solacliq/quotes/view/quote_request_page.dart';
import 'package:solacliq/tasks/cubit/task_cubit.dart';
import 'package:solacliq/tasks/cubit/tasks_cubit.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/tasks/view/task_history_page.dart';
import 'package:solacliq/tasks/view/task_page.dart';
import 'package:solacliq/tasks/view/tasks_tab.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';
import '../tasks/task_fixtures.dart';

/// Every screen outside the auth flow (tested with it) meets the tap
/// target, label and contrast guidelines on a small phone.
void main() {
  final worker = MemberWorkspace(testMembership());
  final agent = MemberWorkspace(
    testMembership(role: OrgRole.agent, payType: PayType.commission),
  );
  final sales = MemberWorkspace(
    testMembership(role: OrgRole.agent, payType: PayType.salary),
  );
  final customer = MemberWorkspace(testMembership(role: OrgRole.customer));
  late MockCustomerRepository customers;
  late MockProfileRepository profiles;
  late MockInstallRepository installs;
  final summary = CustomerSummary(
    id: 'c1',
    name: 'Sunita Rao',
    systemKw: 3,
    place: 'Mohali',
    kyc: KycStatus.needsFix,
    detail: 'Bill photo blurry',
    sentAt: DateTime(2026, 10, 22),
    commission: const Commission(
      amountPaise: 300000,
      status: CommissionStatus.inReview,
    ),
  );
  final install = Install(
    systemKw: 5,
    place: 'Mohali',
    stageIndex: 1,
    stageCount: 3,
    totalPaise: 28500000,
    subsidyPaise: 7800000,
    nextVisit: InstallVisit(
      title: 'Site survey',
      startsAt: DateTime(2026, 10, 23, 11),
      endsAt: DateTime(2026, 10, 23, 12),
      personName: 'Vikram Rana',
      personPhone: '9814000000',
    ),
    stages: const [
      InstallStage(name: 'Site survey', status: StageStatus.next),
      InstallStage(name: 'Structure', status: StageStatus.upcoming),
      InstallStage(name: 'Handover', status: StageStatus.upcoming),
    ],
    payments: const [
      InstallPayment(
        id: 'p1',
        label: 'Advance, 30%',
        detail: 'Due 31 Oct',
        amountPaise: 8550000,
        status: PaymentStatus.due,
      ),
    ],
  );
  late MockWorkspaceCubit workspace;
  late MockHomeRepository homes;
  late MockInviteRepository invites;
  late MockExpenseRepository expenses;
  late MockTaskRepository tasks;
  late MockNotificationRepository notifications;
  final expense = Expense(
    id: 'e1',
    reference: 'EXP-1',
    amountPaise: 45000,
    category: ExpenseCategory.values.first,
    note: 'Diesel for the van',
    spentOn: DateTime(2026, 10, 22),
    status: ExpenseStatus.values.first,
    hasReceipt: true,
  );

  setUpAll(() {
    registerFallbackValue(OrgRole.worker);
    registerFallbackValue(TaskView.today);
  });

  setUp(() {
    customers = MockCustomerRepository();
    when(() => customers.mine(any())).thenAnswer((_) async => [summary]);
    when(() => customers.get(any(), any())).thenAnswer(
      (_) async => CustomerDetail(
        summary: summary,
        phone: '9814000000',
        returned: const ReturnedDocument(
          kind: KycKind.electricityBill,
          title: 'Electricity bill blurry',
          note: AdminNote(text: 'Take it in daylight.', by: 'Rajeeb · Admin'),
        ),
      ),
    );
    profiles = MockProfileRepository();
    when(() => profiles.details()).thenAnswer(
      (_) async => const PersonalDetails(
        phone: '9876511223',
        bank: PayoutBank(holder: 'Meena', last4: '4410', bankName: 'HDFC'),
      ),
    );
    when(() => profiles.settings()).thenAnswer(
      (_) async => const AppSettings(
        push: true,
        whatsapp: false,
        sound: true,
        language: AppLanguage.en,
      ),
    );
    when(() => profiles.documents(any())).thenAnswer(
      (_) async => const MyDocuments(
        items: [
          MyDocument(
            kind: KycKind.aadhaar,
            status: DocumentStatus.verified,
            detail: 'Front and back',
          ),
        ],
      ),
    );
    installs = MockInstallRepository();
    when(() => installs.mine(any())).thenAnswer((_) async => install);
    workspace = MockWorkspaceCubit();
    homes = MockHomeRepository();
    invites = MockInviteRepository();
    expenses = MockExpenseRepository();
    when(() => expenses.mine(any())).thenAnswer((_) async => [expense]);
    when(() => expenses.get(any(), any())).thenAnswer((_) async => expense);
    tasks = MockTaskRepository();
    when(() => tasks.get(any(), any())).thenAnswer((_) async => assignedTask());
    when(() => tasks.history(any(), any())).thenAnswer(
      (_) async => [
        TaskEvent(
          kind: TaskEventKind.assigned,
          actor: admin,
          at: DateTime(2026, 10, 22),
        ),
      ],
    );
    when(() => tasks.list(any(), any())).thenAnswer(
      (_) async => [
        TaskSummary(
          id: 't1',
          reference: 'TSK-1',
          title: 'Panel installation',
          status: TaskStatus.assigned,
          dueAt: DateTime(2026, 10, 23, 10),
          customerName: 'Ramesh Sahoo',
        ),
      ],
    );
    when(() => tasks.stats(any())).thenAnswer(
      (_) async => const WorkerStats(
        tasksThisMonth: 12,
        returnedThisMonth: 1,
        avgMinutesOnSite: 95,
      ),
    );
    notifications = MockNotificationRepository();
    when(() => notifications.list(any())).thenAnswer(
      (_) async => [
        AppNotification(
          id: 'n1',
          kind: NotificationKind.taskReturned,
          title: 'Task returned',
          body: 'Retake the clamp close-up',
          at: DateTime.now(),
          read: false,
          taskId: 't1',
        ),
      ],
    );
    when(() => invites.pending()).thenAnswer((_) async => []);
    when(() => homes.orgHome(any(), any())).thenAnswer(
      (_) async => const HomeSummary(
        eyebrow: 'Today',
        title: "Ravi's day",
        headline: HomeHeadline(value: '3', label: 'tasks'),
        tiles: [
          HomeTile(label: 'Proof due', value: '2', dark: true),
          HomeTile(label: 'Expenses', value: '1'),
        ],
        listTitle: 'Up next',
        rows: [
          HomeRow(
            id: 'r1',
            visual: HomeVisual(initials: 'SR'),
            title: 'Sample',
            detail: 'Detail',
            status: HomeStatus(label: 'Done', tone: HomeTone.success),
          ),
        ],
      ),
    );
  });

  Future<void> check(
    WidgetTester tester,
    Widget page,
    Workspace current,
  ) async {
    when(() => workspace.state)
        .thenReturn(WorkspaceReady(testAccount(), current, [current]));
    await tester.pumpApp(
      page,
      workspaceCubit: workspace,
      repositories: [
        RepositoryProvider<HomeRepository>.value(value: homes),
        RepositoryProvider<InviteRepository>.value(value: invites),
        RepositoryProvider<ExpenseRepository>.value(value: expenses),
        RepositoryProvider<TaskRepository>.value(value: tasks),
        RepositoryProvider<NotificationRepository>.value(value: notifications),
        RepositoryProvider<UploadRepository>.value(
          value: MockUploadRepository(),
        ),
        RepositoryProvider<RegistrationRepository>.value(
          value: MockRegistrationRepository(),
        ),
        RepositoryProvider<CustomerRepository>.value(value: customers),
        RepositoryProvider<ProfileRepository>.value(value: profiles),
        RepositoryProvider<InstallRepository>.value(value: installs),
      ],
    );
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  final pages = <String, (Widget, Workspace)>{
    'intro': (const IntroPage(), const PersonalWorkspace()),
    'request access': (const RequestAccessPage(), const PersonalWorkspace()),
    'personal home': (const HomePage(), const PersonalWorkspace()),
    'worker home': (const HomePage(), worker),
    'quote': (
      QuoteRequestPage(account: testAccount()),
      const PersonalWorkspace(),
    ),
    'invite': (
      InvitePage(
        invite: Invite(
          id: 'i1',
          orgId: 'o1',
          orgName: 'Example Solar',
          role: OrgRole.worker,
          invitedBy: 'Dev',
          invitedAt: DateTime(2026, 10, 20),
        ),
      ),
      const PersonalWorkspace(),
    ),
    'log expense': (ExpensePage(workspace: worker), worker),
    'add customer': (AddCustomerPage(workspace: agent), agent),
    'tasks tab': (
      BlocProvider(
        create: (context) {
          final cubit = TasksCubit(context.read(), orgId: 'o1');
          unawaited(cubit.load());
          return cubit;
        },
        child: const TasksTab(),
      ),
      worker,
    ),
    'task': (
      BlocProvider(
        create: (context) {
          final cubit = TaskCubit(
            context.read(),
            context.read(),
            orgId: 'o1',
            taskId: 't1',
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: const TaskPage(),
      ),
      worker,
    ),
    'task history': (const TaskHistoryPage(orgId: 'o1', taskId: 't1'), worker),
    'expenses tab': (const ExpensesTab(orgId: 'o1'), worker),
    'expense detail': (
      ExpenseDetailPage(workspace: worker, expenseId: 'e1'),
      worker,
    ),
    'notifications': (const NotificationsPage(orgId: 'o1'), worker),
    'worker profile': (
      ProfileTab(
        account: testAccount(),
        workspace: worker,
        onTaskHistory: () {},
      ),
      worker,
    ),
    'sales profile': (
      ProfileTab(account: testAccount(), workspace: agent),
      agent,
    ),
    'salaried profile': (
      ProfileTab(account: testAccount(), workspace: sales),
      sales,
    ),
    'customer profile': (
      ProfileTab(account: testAccount(), workspace: customer),
      customer,
    ),
    'personal profile': (
      ProfileTab(account: testAccount(), pushed: true),
      const PersonalWorkspace(),
    ),
    'sales home': (const HomePage(), agent),
    'salaried home': (const HomePage(), sales),
    'customer home': (const HomePage(), customer),
    'customers tab': (const CustomersTab(orgId: 'o1'), agent),
    'customer': (CustomerPage(workspace: agent, customerId: 'c1'), agent),
    'fix document': (
      FixDocumentPage(workspace: agent, customerId: 'c1'),
      agent,
    ),
    'earnings': (const EarningsTab(orgId: 'o1'), agent),
    'track': (const TrackTab(orgId: 'o1'), customer),
    'payments': (PaymentsTab(workspace: customer), customer),
    'settings': (const SettingsPage(), worker),
    'personal details': (DetailsPage(account: testAccount()), worker),
    'bank': (const BankPage(title: 'Bank for payouts'), agent),
    'documents': (DocumentsPage(workspace: worker), worker),
    'learn': (const LearnPage(), const PersonalWorkspace()),
  };

  for (final MapEntry(key: name, value: (page, current)) in pages.entries) {
    testWidgets('$name meets the guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await check(tester, page, current);
      handle.dispose();
    });
  }
}
