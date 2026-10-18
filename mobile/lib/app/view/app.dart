import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/app/router.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/health/data/health_repository.dart';
import 'package:solacliq/l10n/l10n.dart';

class App extends StatefulWidget {
  const new({required this.config, this.dio, this.tokenStore, super.key});

  final AppConfig config;

  /// For tests: a Dio with a fake adapter. Otherwise one is made for
  /// [config] and closed with the app.
  final Dio? dio;

  /// For tests. Otherwise the phone's secure storage.
  final TokenStore? tokenStore;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final Dio _dio;
  late final ApiClient _api;
  late final AuthRepository _auth;
  late final HealthRepository _health;
  late final AppRouter _router;

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
    _health = HealthRepository(_api.getSystemApi());
    _router = AppRouter(widget.config, _auth);
    unawaited(_auth.restore());
  }

  @override
  void dispose() {
    _router.dispose();
    unawaited(_auth.dispose());
    if (widget.dio == null) _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.config),
        RepositoryProvider.value(value: _auth),
        RepositoryProvider.value(value: _health),
      ],
      child: MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appName,
        theme: SolaTheme.light(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router.router,
      ),
    );
  }
}
