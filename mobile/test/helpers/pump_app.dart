import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/health/data/health_repository.dart';
import 'package:solacliq/l10n/l10n.dart';

import 'mocks.dart';

const testConfig = AppConfig(
  flavor: AppFlavor.development,
  apiBaseUrl: 'http://localhost:4010',
);

/// Every route except the page under test, as a placeholder that shows its
/// full location, so tests can check where a page navigated.
const List<String> _otherRoutes = [
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.verify,
  AppRoutes.forgot,
  AppRoutes.reset,
  AppRoutes.account,
  AppRoutes.gallery,
];

extension PumpApp on WidgetTester {
  /// Pumps [page] as the first route, with the app's theme, strings, config
  /// and repositories (mocks unless given).
  Future<GoRouter> pumpApp(
    Widget page, {
    AuthRepository? authRepository,
    HealthRepository? healthRepository,
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
        ],
        child: MaterialApp.router(
          theme: SolaTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    return router;
  }
}
