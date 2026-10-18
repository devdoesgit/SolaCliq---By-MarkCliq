import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/app/app.dart';
import 'package:solacliq/app/router.dart';
import 'package:solacliq/auth/auth.dart';

void main() {
  const account = Account(
    id: '1',
    name: 'A',
    email: 'a@example.com',
    isPlatformAdmin: false,
    memberships: [],
  );
  const dev = AppConfig(flavor: AppFlavor.development, apiBaseUrl: '');
  final prod = AppConfig.production();

  group('authRedirect', () {
    test('while unknown, everything waits on the splash', () {
      expect(authRedirect(const AuthUnknown(), '/', dev), isNull);
      expect(authRedirect(const AuthUnknown(), '/account', dev), '/');
      expect(authRedirect(const AuthUnknown(), '/login', dev), '/');
    });

    test('signed out: public pages stay, others go to welcome', () {
      for (final path in AppRoutes.public) {
        expect(authRedirect(const AuthUnauthenticated(), path, dev), isNull);
      }
      expect(authRedirect(const AuthUnauthenticated(), '/', dev), '/welcome');
      expect(
        authRedirect(const AuthUnauthenticated(), '/account', dev),
        '/welcome',
      );
    });

    test('signed in: auth pages and splash go to account', () {
      const status = AuthAuthenticated(account);
      for (final path in [...AppRoutes.public, '/']) {
        expect(authRedirect(status, path, dev), '/account');
      }
      expect(authRedirect(status, '/account', dev), isNull);
    });

    test('the gallery is open in development only', () {
      expect(
        authRedirect(const AuthUnauthenticated(), '/gallery', dev),
        isNull,
      );
      expect(
        authRedirect(const AuthUnauthenticated(), '/gallery', prod),
        '/welcome',
      );
    });
  });
}
