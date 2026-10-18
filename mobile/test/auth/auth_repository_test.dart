import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/auth/auth.dart';

import '../helpers/helpers.dart';

void main() {
  final now = DateTime.utc(2026, 10, 18, 12);
  late FakeTokenStore store;
  late FakeAdapter adapter;
  late Dio dio;
  late AuthRepository repository;
  late Future<ResponseBody> Function(RequestOptions) answer;

  StoredSession session({DateTime? expiresAt, Map<String, Object?>? account}) =>
      StoredSession(
        accessToken: 'stored-access',
        refreshToken: 'stored-refresh',
        accessExpiresAt: expiresAt ?? now.add(const Duration(minutes: 10)),
        accountJson: account,
      );

  setUp(() {
    store = FakeTokenStore();
    answer = (_) async => jsonBody(500, problem(500, 'unexpected'));
    adapter = FakeAdapter((o) => answer(o));
    dio = Dio(BaseOptions(baseUrl: 'http://api'))..httpClientAdapter = adapter;
    repository = AuthRepository(
      authApi: ApiClient(dio: dio, interceptors: []).getAuthApi(),
      store: store,
      clock: () => now,
    );
    dio.interceptors.add(AuthInterceptor(repository: repository, dio: dio));
  });

  tearDown(() => repository.dispose());

  group('logIn', () {
    test('stores the tokens and account, and signs in', () async {
      answer = (_) async =>
          jsonBody(200, {'user': meJson(name: 'Asha'), 'tokens': tokensJson()});
      final statuses = <AuthStatus>[];
      final sub = repository.statusChanges.listen(statuses.add);

      await repository.logIn(email: 'person@example.com', password: 'secret');

      final request = adapter.requests.single;
      expect(request.path, '/auth/login');
      expect(request.data as String, contains('"client":"app"'));
      expect(store.session!.accessToken, 'access-1');
      expect(store.session!.refreshToken, 'refresh-1');
      expect(
        store.session!.accessExpiresAt,
        now.add(const Duration(seconds: 900)),
      );
      expect(repository.status, isA<AuthAuthenticated>());
      await Future<void>.delayed(Duration.zero);
      expect(statuses.single, isA<AuthAuthenticated>());
      expect((statuses.single as AuthAuthenticated).account.name, 'Asha');
      await sub.cancel();
    });

    test('maps problem codes to failures', () async {
      for (final (status, code, expected) in [
        (401, 'auth.invalid_credentials', AuthFailureCode.invalidCredentials),
        (403, 'account.email_unverified', AuthFailureCode.emailUnverified),
        (429, 'auth.too_many_attempts', AuthFailureCode.tooManyAttempts),
      ]) {
        answer = (_) async => jsonBody(status, problem(status, code));
        await expectLater(
          repository.logIn(email: 'a@example.com', password: 'x'),
          throwsA(isA<AuthFailure>().having((f) => f.code, 'code', expected)),
        );
      }
      expect(store.session, isNull);
    });

    test('no connection is a network failure', () async {
      answer = (o) => Future.error(
        DioException.connectionError(requestOptions: o, reason: 'offline'),
      );
      await expectLater(
        repository.logIn(email: 'a@example.com', password: 'x'),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailureCode.network,
          ),
        ),
      );
    });
  });

  group('restore', () {
    test('nothing stored: signed out', () async {
      await repository.restore();
      expect(repository.status, const AuthUnauthenticated());
      expect(adapter.requests, isEmpty);
    });

    test('opens with the cached account when offline', () async {
      store.session = session(account: meJson(name: 'Cached'));
      answer = (o) => Future.error(
        DioException.connectionError(requestOptions: o, reason: 'offline'),
      );
      await repository.restore();
      final status = repository.status as AuthAuthenticated;
      expect(status.account.name, 'Cached');
      expect(store.session, isNotNull);
    });

    test('refreshes the account from the server with the token', () async {
      store.session = session(account: meJson(name: 'Old'));
      answer = (_) async => jsonBody(200, meJson(name: 'New'));
      await repository.restore();
      expect(adapter.requests.single.path, '/me');
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer stored-access',
      );
      expect((repository.status as AuthAuthenticated).account.name, 'New');
      expect(store.session!.accountJson!['name'], 'New');
    });

    test('a rejected login signs out and forgets the tokens', () async {
      store.session = session(account: meJson());
      answer = (o) async => o.path == '/auth/refresh'
          ? jsonBody(401, problem(401, 'auth.session_expired'))
          : jsonBody(401, problem(401, 'auth.session_expired'));
      await repository.restore();
      expect(repository.status, const AuthUnauthenticated());
      expect(store.session, isNull);
    });
  });

  group('tokens', () {
    test('an expired access token is refreshed before the request', () async {
      store.session = session(
        expiresAt: now.subtract(const Duration(minutes: 1)),
      );
      answer = (o) async => switch (o.path) {
        '/auth/refresh' => jsonBody(
          200,
          tokensJson(access: 'access-2', refresh: 'refresh-2'),
        ),
        _ => jsonBody(200, meJson()),
      };
      await repository.restore();
      expect(adapter.requests.map((r) => r.path), ['/auth/refresh', '/me']);
      expect(adapter.requests.last.headers['Authorization'], 'Bearer access-2');
      expect(store.session!.refreshToken, 'refresh-2');
    });

    test('concurrent callers share one refresh', () async {
      answer = (_) async =>
          jsonBody(200, {'user': meJson(), 'tokens': tokensJson(expiresIn: 0)});
      await repository.logIn(email: 'a@example.com', password: 'x');
      adapter.requests.clear();
      final gate = Completer<void>();
      answer = (o) async {
        await gate.future;
        return jsonBody(200, tokensJson(access: 'access-3'));
      };
      final a = repository.accessToken();
      final b = repository.refreshAccessToken();
      gate.complete();
      expect(await a, 'access-3');
      expect(await b, 'access-3');
      expect(
        adapter.requests.where((r) => r.path == '/auth/refresh'),
        hasLength(1),
      );
    });

    test('a server error at start-up keeps the person signed in', () async {
      store.session = session(account: meJson(name: 'Cached'));
      answer = (_) async => jsonBody(500, problem(500, 'internal'));
      await repository.restore();
      expect((repository.status as AuthAuthenticated).account.name, 'Cached');
      expect(store.session, isNotNull);
    });

    test('a 401 on a request refreshes once and retries it', () async {
      store.session = session(account: meJson());
      var meCalls = 0;
      answer = (o) async {
        if (o.path == '/auth/refresh') {
          return jsonBody(200, tokensJson(access: 'access-4'));
        }
        meCalls++;
        return meCalls == 1
            ? jsonBody(401, problem(401, 'auth.session_expired'))
            : jsonBody(200, meJson(name: 'After retry'));
      };
      await repository.restore();
      expect(meCalls, 2);
      expect(adapter.requests.last.headers['Authorization'], 'Bearer access-4');
      expect(
        (repository.status as AuthAuthenticated).account.name,
        'After retry',
      );
    });

    test('auth endpoints never carry a token', () async {
      store.session = session(account: meJson());
      answer = (_) async => jsonBody(202, null);
      await repository.restore().catchError((_) {});
      adapter.requests.clear();
      await repository.requestPasswordReset(email: 'a@example.com');
      expect(adapter.requests.single.headers['Authorization'], isNull);
    });
  });

  group('logOut', () {
    test('forgets the login even when offline', () async {
      store.session = session(account: meJson());
      answer = (o) => o.path == '/me'
          ? Future.value(jsonBody(200, meJson()))
          : Future.error(
              DioException.connectionError(
                requestOptions: o,
                reason: 'offline',
              ),
            );
      await repository.restore();
      await repository.logOut();
      expect(store.session, isNull);
      expect(repository.status, const AuthUnauthenticated());
    });
  });

  group('codes', () {
    test('a wrong code is codeInvalid', () async {
      answer = (_) async => jsonBody(400, problem(400, 'auth.code_invalid'));
      await expectLater(
        repository.verifyEmail(email: 'a@example.com', code: '123456'),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailureCode.codeInvalid,
          ),
        ),
      );
    });
  });
}
