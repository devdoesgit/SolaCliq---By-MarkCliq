import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/access/view/request_access_page.dart';
import 'package:solacliq/access/view/request_sent_page.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/view/splash_page.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/forgot_password_page.dart';
import 'package:solacliq/auth/view/intro_page.dart';
import 'package:solacliq/auth/view/login_page.dart';
import 'package:solacliq/auth/view/reset_password_page.dart';
import 'package:solacliq/auth/view/signup_page.dart';
import 'package:solacliq/auth/view/verify_email_page.dart';
import 'package:solacliq/auth/view/welcome_page.dart';
import 'package:solacliq/customers/view/add_customer_page.dart';
import 'package:solacliq/customers/view/add_customer_sent_page.dart';
import 'package:solacliq/customers/view/customer_page.dart';
import 'package:solacliq/customers/view/fix_document_page.dart';
import 'package:solacliq/expenses/view/expense_detail_page.dart';
import 'package:solacliq/expenses/view/expense_page.dart';
import 'package:solacliq/expenses/view/expense_sent_page.dart';
import 'package:solacliq/gallery/view/gallery_page.dart';
import 'package:solacliq/home/view/home_page.dart';
import 'package:solacliq/invites/data/invite_repository.dart';
import 'package:solacliq/invites/view/invite_page.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/learn/view/learn_page.dart';
import 'package:solacliq/notifications/view/notifications_page.dart';
import 'package:solacliq/profile/view/bank_page.dart';
import 'package:solacliq/profile/view/details_page.dart';
import 'package:solacliq/profile/view/documents_page.dart';
import 'package:solacliq/profile/view/profile_tab.dart';
import 'package:solacliq/profile/view/settings_page.dart';
import 'package:solacliq/quotes/view/quote_request_page.dart';
import 'package:solacliq/quotes/view/quote_sent_page.dart';
import 'package:solacliq/tasks/cubit/task_cubit.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/tasks/view/proof_camera_page.dart';
import 'package:solacliq/tasks/view/task_history_page.dart';
import 'package:solacliq/tasks/view/task_page.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';
import 'package:solacliq/workspace/view/admin_only_page.dart';

export 'package:solacliq/app/routes.dart';

/// Where to send someone, given their sign-in and workspace. Null keeps
/// them where they are.
@visibleForTesting
String? appRedirect(WorkspaceState state, String location, AppConfig config) {
  if (location == AppRoutes.gallery) {
    // Development only; elsewhere the route doesn't exist.
    return config.showDevTools ? null : AppRoutes.home;
  }
  String? only(String path) => location == path ? null : path;
  return switch (state) {
    WorkspaceLoading() => only(AppRoutes.splash),
    WorkspaceSignedOut() =>
      AppRoutes.public.contains(location) ? null : AppRoutes.welcome,
    WorkspaceAdminOnly() => only(AppRoutes.useWebsite),
    // Signed in: the entry screens lead home; in-app screens stay.
    WorkspaceReady() =>
      AppRoutes.public.contains(location) ||
              location == AppRoutes.splash ||
              location == AppRoutes.useWebsite
          ? AppRoutes.home
          : null,
  };
}

/// The app's router and the listener that re-checks [appRedirect]
/// whenever the workspace changes. Dispose it to release both.
class AppRouter {
  factory(AppConfig config, WorkspaceCubit workspace) {
    final refresh = _StateListenable(workspace.stream, workspace.state);
    final router = GoRouter(
      refreshListenable: refresh,
      redirect: (context, state) =>
          appRedirect(workspace.state, state.matchedLocation, config),
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const WelcomePage(),
        ),
        GoRoute(
          path: AppRoutes.intro,
          builder: (context, state) => const IntroPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) {
            final params = state.uri.queryParameters;
            return LoginPage(
              initialEmail: params['email'],
              notice: switch (params['notice']) {
                'verified' => LoginNotice.emailVerified,
                'reset' => LoginNotice.passwordChanged,
                'setup' => LoginNotice.passwordCreated,
                _ => null,
              },
            );
          },
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) => const SignupPage(),
        ),
        GoRoute(
          path: AppRoutes.verify,
          builder: (context, state) =>
              VerifyEmailPage(email: state.uri.queryParameters['email'] ?? ''),
        ),
        GoRoute(
          path: AppRoutes.forgot,
          builder: (context, state) => ForgotPasswordPage(
            initialEmail: state.uri.queryParameters['email'],
            setup: state.uri.queryParameters['setup'] == '1',
          ),
        ),
        GoRoute(
          path: AppRoutes.reset,
          builder: (context, state) => ResetPasswordPage(
            setup: state.uri.queryParameters['setup'] == '1',
            email: state.uri.queryParameters['email'] ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.requestAccess,
          builder: (context, state) => const RequestAccessPage(),
        ),
        GoRoute(
          path: AppRoutes.requestSent,
          builder: (context, state) => RequestSentPage(
            company: state.uri.queryParameters['company'] ?? '',
            email: state.uri.queryParameters['email'] ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.quote,
          builder: (context, state) => switch (workspace.state) {
            WorkspaceReady(:final account) => QuoteRequestPage(
              account: account,
            ),
            _ => const SplashPage(),
          },
        ),
        GoRoute(
          path: AppRoutes.quoteSent,
          redirect: (context, state) =>
              state.extra is QuoteSentArgs ? null : AppRoutes.home,
          builder: (context, state) =>
              QuoteSentPage(args: state.extra! as QuoteSentArgs),
        ),
        GoRoute(
          path: '${AppRoutes.invite}/:id',
          // The invite comes from the home's banner; without it (a fresh
          // start) the banner is the way back in.
          redirect: (context, state) =>
              state.extra is Invite ? null : AppRoutes.home,
          builder: (context, state) =>
              InvitePage(invite: state.extra! as Invite),
        ),
        GoRoute(
          path: AppRoutes.expense,
          builder: (context, state) => switch (workspace.state) {
            WorkspaceReady(:final MemberWorkspace current) => ExpensePage(
              workspace: current,
            ),
            _ => const SplashPage(),
          },
        ),
        GoRoute(
          path: AppRoutes.expenseSent,
          redirect: (context, state) =>
              state.extra is ExpenseSentArgs ? null : AppRoutes.home,
          builder: (context, state) =>
              ExpenseSentPage(args: state.extra! as ExpenseSentArgs),
        ),
        GoRoute(
          path: AppRoutes.addCustomer,
          builder: (context, state) => switch (workspace.state) {
            WorkspaceReady(:final MemberWorkspace current) => AddCustomerPage(
              workspace: current,
            ),
            _ => const SplashPage(),
          },
        ),
        GoRoute(
          path: AppRoutes.addCustomerSent,
          redirect: (context, state) =>
              state.extra is AddCustomerSentArgs ? null : AppRoutes.home,
          builder: (context, state) =>
              AddCustomerSentPage(args: state.extra! as AddCustomerSentArgs),
        ),
        GoRoute(
          path: '${AppRoutes.tasks}/:id',
          builder: (context, state) => _member(
            workspace,
            (current) => _withTask(context, state, current, const TaskPage()),
          ),
          routes: [
            GoRoute(
              path: 'camera',
              builder: (context, state) => _member(
                workspace,
                (current) => _withTask(
                  context,
                  state,
                  current,
                  ProofCameraPage(
                    slotId: state.uri.queryParameters['slot'],
                    returnsToTask: state.uri.queryParameters['tab'] != '1',
                  ),
                ),
              ),
            ),
            GoRoute(
              path: 'history',
              builder: (context, state) => _member(
                workspace,
                (current) => TaskHistoryPage(
                  orgId: current.orgId,
                  taskId: state.pathParameters['id']!,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '${AppRoutes.expenses}/:id',
          builder: (context, state) => _member(
            workspace,
            (current) => ExpenseDetailPage(
              workspace: current,
              expenseId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => switch (workspace.state) {
            WorkspaceReady(:final MemberWorkspace current) => NotificationsPage(
              orgId: current.orgId,
              background: _background(current),
            ),
            WorkspaceReady() => const NotificationsPage(
              orgId: null,
              background: SolaBackground.cream,
            ),
            _ => const SplashPage(),
          },
        ),
        GoRoute(
          path: '${AppRoutes.customers}/:id',
          builder: (context, state) => _member(
            workspace,
            (current) => CustomerPage(
              workspace: current,
              customerId: state.pathParameters['id']!,
            ),
          ),
          routes: [
            GoRoute(
              path: 'fix',
              builder: (context, state) => _member(
                workspace,
                (current) => FixDocumentPage(
                  workspace: current,
                  customerId: state.pathParameters['id']!,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.details,
          builder: (context, state) => switch (workspace.state) {
            WorkspaceReady(:final account) => DetailsPage(account: account),
            _ => const SplashPage(),
          },
        ),
        GoRoute(
          path: AppRoutes.bank,
          builder: (context, state) => _member(
            workspace,
            (current) => BankPage(
              title: current.role == OrgRole.worker
                  ? context.l10n.bankForSalary
                  : context.l10n.bankForPayouts,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.documents,
          builder: (context, state) => _member(
            workspace,
            (current) => DocumentsPage(workspace: current),
          ),
        ),
        GoRoute(
          path: AppRoutes.learn,
          builder: (context, state) => const LearnPage(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => switch (workspace.state) {
            WorkspaceReady(:final account) => ProfileTab(
              account: account,
              pushed: true,
            ),
            _ => const SplashPage(),
          },
        ),
        GoRoute(
          path: AppRoutes.useWebsite,
          builder: (context, state) => const AdminOnlyPage(),
        ),
        if (config.showDevTools)
          GoRoute(
            path: AppRoutes.gallery,
            builder: (context, state) => const GalleryPage(),
          ),
      ],
    );
    // A new workspace (a switch, or another person signing in) starts at
    // its home, so no screen of the old one stays open.
    refresh.onWorkspaceChanged = () => router.go(AppRoutes.home);
    return AppRouter._(router, refresh);
  }

  new _(this.router, this._refresh);

  final GoRouter router;
  final _StateListenable _refresh;

  void dispose() {
    router.dispose();
    _refresh.dispose();
  }
}

/// Builds a company screen for the workspace in use, or the splash while
/// there is none (a moment at start-up).
Widget _member(
  WorkspaceCubit workspace,
  Widget Function(MemberWorkspace current) build,
) => switch (workspace.state) {
  WorkspaceReady(:final MemberWorkspace current) => build(current),
  _ => const SplashPage(),
};

/// The role's tint, so a screen opened from a home matches it.
SolaBackground _background(MemberWorkspace w) => switch (w.role) {
  OrgRole.agent => SolaBackground.stone,
  OrgRole.customer => SolaBackground.sky,
  _ => SolaBackground.sand,
};

/// Gives [page] the task's cubit: the one passed in `extra` (the task and
/// its camera share it), or a new one that loads the task.
Widget _withTask(
  BuildContext context,
  GoRouterState state,
  MemberWorkspace current,
  Widget page,
) {
  if (state.extra case final TaskCubit cubit) {
    return BlocProvider.value(value: cubit, child: page);
  }
  return BlocProvider(
    create: (context) {
      final cubit = TaskCubit(
        context.read<TaskRepository>(),
        context.read<UploadRepository>(),
        orgId: current.orgId,
        taskId: state.pathParameters['id']!,
      );
      unawaited(cubit.load());
      return cubit;
    },
    child: page,
  );
}

/// Bridges the workspace stream to the router's refresh listenable.
class _StateListenable extends ChangeNotifier {
  new(Stream<WorkspaceState> stream, WorkspaceState initial) {
    _shown = _workspaceId(initial);
    _subscription = stream.listen((state) {
      final id = _workspaceId(state);
      final changed = _shown != null && id != null && id != _shown;
      _shown = id;
      notifyListeners();
      if (changed) onWorkspaceChanged?.call();
    });
  }

  /// Called when the workspace in use becomes another one.
  VoidCallback? onWorkspaceChanged;

  String? _shown;

  static String? _workspaceId(WorkspaceState state) =>
      state is WorkspaceReady ? state.current.id : null;

  late final StreamSubscription<WorkspaceState> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
