import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/app/dev/mock_persona.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';
import 'package:solacliq/health/data/health_repository.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';

import 'mocks.dart';

const testConfig = AppConfig(
  flavor: AppFlavor.development,
  apiBaseUrl: 'http://localhost:4010',
);

/// Every route except the page under test, as a placeholder that shows its
/// full location, so tests can check where a page navigated.
const List<String> _otherRoutes = [
  AppRoutes.welcome,
  AppRoutes.intro,
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.verify,
  AppRoutes.forgot,
  AppRoutes.reset,
  AppRoutes.requestAccess,
  AppRoutes.requestSent,
  AppRoutes.home,
  AppRoutes.quote,
  AppRoutes.quoteSent,
  AppRoutes.expense,
  AppRoutes.expenseSent,
  AppRoutes.addCustomer,
  AppRoutes.addCustomerSent,
  AppRoutes.useWebsite,
  AppRoutes.notifications,
  '${AppRoutes.tasks}/:id',
  '${AppRoutes.tasks}/:id/camera',
  '${AppRoutes.tasks}/:id/history',
  '${AppRoutes.expenses}/:id',
  AppRoutes.gallery,
];

/// A task repository with nothing in it.
TaskRepository _emptyTasks() {
  registerFallbackValue(TaskView.today);
  final tasks = MockTaskRepository();
  when(() => tasks.list(any(), any())).thenAnswer((_) async => []);
  when(() => tasks.stats(any())).thenAnswer(
    (_) async => const WorkerStats(
      tasksThisMonth: 0,
      returnedThisMonth: 0,
      avgMinutesOnSite: 0,
    ),
  );
  return tasks;
}

/// An expense repository with nothing in it.
ExpenseRepository _emptyExpenses() {
  final expenses = MockExpenseRepository();
  when(() => expenses.mine(any())).thenAnswer((_) async => []);
  return expenses;
}

extension PumpApp on WidgetTester {
  /// Pumps [page] as the first route, with the app's theme, strings, config
  /// and repositories (mocks unless given).
  Future<GoRouter> pumpApp(
    Widget page, {
    AuthRepository? authRepository,
    HealthRepository? healthRepository,
    WorkspaceCubit? workspaceCubit,
    MockPersonaInterceptor? persona,
    List<RepositoryProvider<Object>> repositories = const [],
    AppConfig config = testConfig,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => page),
        for (final path in _otherRoutes)
          GoRoute(
            path: path,
            builder: (_, state) => Scaffold(body: Text('route:${state.uri}')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: config),
          RepositoryProvider<AuthRepository>.value(
            value: authRepository ?? MockAuthRepository(),
          ),
          RepositoryProvider<HealthRepository>.value(
            value: healthRepository ?? MockHealthRepository(),
          ),
          RepositoryProvider<MockPersonaInterceptor>.value(
            value: persona ?? MockPersonaInterceptor(),
          ),
          RepositoryProvider(create: (_) => PendingLogin()),
          // Off, so tests exercise validation.
          RepositoryProvider(
            create: (_) => QuickForms(available: false),
            dispose: (quick) => quick.dispose(),
          ),
          // Empty unless a test gives its own.
          RepositoryProvider<TaskRepository>.value(value: _emptyTasks()),
          RepositoryProvider<ExpenseRepository>.value(value: _emptyExpenses()),
          ...repositories,
        ],
        child: BlocProvider<WorkspaceCubit>.value(
          value: workspaceCubit ?? MockWorkspaceCubit(),
          child: MaterialApp.router(
            theme: SolaTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    return router;
  }
}

extension TapVisible on WidgetTester {
  /// Scrolls the widget with [key] into view, then taps it, as a person
  /// would on a screen taller than the test window. Settles first, so don't
  /// use it while something is meant to be mid-animation.
  Future<void> tapKey(String key) async {
    final finder = find.byKey(Key(key));
    // Focusing a field scrolls it into view with an animation; let that
    // finish so the target isn't moving under the tap.
    await pumpAndSettle();
    await ensureVisible(finder);
    await pumpAndSettle();
    await tap(finder);
  }
}
