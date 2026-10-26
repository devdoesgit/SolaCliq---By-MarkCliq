import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/access/data/access_repository.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/app/dev/mock_persona.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/router.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';
import 'package:solacliq/health/data/health_repository.dart';
import 'package:solacliq/home/data/home_repository.dart';
import 'package:solacliq/install/data/install_repository.dart';
import 'package:solacliq/invites/data/invite_repository.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/notifications/data/notification_repository.dart';
import 'package:solacliq/profile/data/profile_repository.dart';
import 'package:solacliq/quotes/data/quote_repository.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace_store.dart';

class App extends StatefulWidget {
  const new({
    required this.config,
    this.dio,
    this.tokenStore,
    this.workspaceStore,
    super.key,
  });

  final AppConfig config;

  /// For tests: a Dio with a fake adapter. Otherwise one is made for
  /// [config] and closed with the app.
  final Dio? dio;

  /// For tests. Otherwise the phone's secure storage.
  final TokenStore? tokenStore;

  /// For tests. Otherwise the phone's secure storage.
  final WorkspaceStore? workspaceStore;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final Dio _dio;

  /// Sends upload bytes to storage: no base URL, no auth header.
  final Dio _transfer = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(minutes: 2),
    ),
  );
  late final ApiClient _api;
  late final AuthRepository _auth;
  late final HealthRepository _health;
  late final WorkspaceCubit _workspace;
  late final AppRouter _router;
  late final MockPersonaInterceptor _persona;
  late final AppLifecycleListener _lifecycle;
  final _pendingLogin = PendingLogin();
  late final QuickForms _quickForms = QuickForms(
    available: widget.config.showDevTools,
  );

  @override
  void initState() {
    super.initState();
    _dio =
        widget.dio ??
        Dio(
          BaseOptions(
            baseUrl: widget.config.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );
    _api = ApiClient(dio: _dio, interceptors: []);
    _auth = AuthRepository(
      authApi: _api.getAuthApi(),
      store: widget.tokenStore ?? SecureTokenStore(),
    );
    _dio.interceptors.add(AuthInterceptor(repository: _auth, dio: _dio));
    _persona = MockPersonaInterceptor(MockPersona.fromDefine());
    if (widget.config.showDevTools) _dio.interceptors.add(_persona);
    _health = HealthRepository(_api.getSystemApi());
    _workspace = WorkspaceCubit(
      auth: _auth,
      store: widget.workspaceStore ?? SecureWorkspaceStore(),
    );
    _router = AppRouter(widget.config, _workspace);
    // Back in the app: pick up new companies, removals and suspensions.
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_auth.refreshAccount()),
    );
    unawaited(_auth.restore());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    unawaited(_workspace.close());
    _persona.dispose();
    _quickForms.dispose();
    unawaited(_auth.dispose());
    if (widget.dio == null) _dio.close();
    _transfer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.config),
        RepositoryProvider.value(value: _auth),
        RepositoryProvider.value(value: _health),
        RepositoryProvider.value(value: _persona),
        RepositoryProvider.value(value: _pendingLogin),
        RepositoryProvider.value(value: _quickForms),
        RepositoryProvider(
          create: (_) => AccessRepository(_api.getOnboardingApi()),
        ),
        RepositoryProvider(create: (_) => HomeRepository(_api.getHomeApi())),
        RepositoryProvider(
          create: (_) => InviteRepository(_api.getOnboardingApi(), _auth),
        ),
        RepositoryProvider(create: (_) => QuoteRepository(_api.getQuotesApi())),
        RepositoryProvider(
          create: (_) => UploadRepository(_api.getUploadsApi(), _transfer),
        ),
        RepositoryProvider(
          create: (_) => ExpenseRepository(_api.getExpensesApi()),
        ),
        RepositoryProvider(
          create: (_) => RegistrationRepository(_api.getCustomersApi()),
        ),
        RepositoryProvider(create: (_) => TaskRepository(_api.getTasksApi())),
        RepositoryProvider(
          create: (_) => CustomerRepository(_api.getCustomersApi()),
        ),
        RepositoryProvider(
          create: (_) => ProfileRepository(_api.getProfileApi()),
        ),
        RepositoryProvider(
          create: (_) => InstallRepository(_api.getInstallApi()),
        ),
        RepositoryProvider(
          create: (_) => NotificationRepository(_api.getNotificationsApi()),
        ),
      ],
      child: BlocProvider.value(
        value: _workspace,
        child: MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.appName,
          theme: SolaTheme.light(),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router.router,
        ),
      ),
    );
  }
}
