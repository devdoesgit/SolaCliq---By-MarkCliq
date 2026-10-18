import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:solacliq/account/view/account_page.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/view/splash_page.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/forgot_password_page.dart';
import 'package:solacliq/auth/view/login_page.dart';
import 'package:solacliq/auth/view/reset_password_page.dart';
import 'package:solacliq/auth/view/signup_page.dart';
import 'package:solacliq/auth/view/verify_email_page.dart';
import 'package:solacliq/auth/view/welcome_page.dart';
import 'package:solacliq/gallery/view/gallery_page.dart';

export 'package:solacliq/app/routes.dart';

/// Where to send someone, given whether they are signed in. Null keeps
/// them where they are.
@visibleForTesting
String? authRedirect(AuthStatus status, String location, AppConfig config) {
  if (location == AppRoutes.gallery && config.showDevTools) return null;
  final isPublic = AppRoutes.public.contains(location);
  return switch (status) {
    AuthUnknown() => location == AppRoutes.splash ? null : AppRoutes.splash,
    AuthUnauthenticated() => isPublic ? null : AppRoutes.welcome,
    AuthAuthenticated() =>
      isPublic || location == AppRoutes.splash ? AppRoutes.account : null,
  };
}

/// The app's router and the listener that re-checks [authRedirect]
/// whenever the sign-in state changes. Dispose it to release both.
class AppRouter {
  factory(AppConfig config, AuthRepository auth) {
    final refresh = _StatusListenable(auth.statusChanges);
    final router = GoRouter(
      refreshListenable: refresh,
      redirect: (context, state) =>
          authRedirect(auth.status, state.matchedLocation, config),
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
          path: AppRoutes.login,
          builder: (context, state) {
            final params = state.uri.queryParameters;
            return LoginPage(
              initialEmail: params['email'],
              notice: switch (params['notice']) {
                'verified' => LoginNotice.emailVerified,
                'reset' => LoginNotice.passwordChanged,
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
          ),
        ),
        GoRoute(
          path: AppRoutes.reset,
          builder: (context, state) => ResetPasswordPage(
            email: state.uri.queryParameters['email'] ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.account,
          builder: (context, state) => const AccountPage(),
        ),
        if (config.showDevTools)
          GoRoute(
            path: AppRoutes.gallery,
            builder: (context, state) => const GalleryPage(),
          ),
      ],
    );
    return AppRouter._(router, refresh);
  }

  new _(this.router, this._refresh);

  final GoRouter router;
  final _StatusListenable _refresh;

  void dispose() {
    router.dispose();
    _refresh.dispose();
  }
}

/// Bridges the auth status stream to the router's refresh listenable.
class _StatusListenable extends ChangeNotifier {
  new(Stream<AuthStatus> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthStatus> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
