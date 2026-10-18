import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:solacliq/account/view/account_page.dart';
import 'package:solacliq/app/app.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/welcome_page.dart';

import '../helpers/helpers.dart';

Dio _dio(Future<ResponseBody> Function(RequestOptions) handler) =>
    Dio(BaseOptions(baseUrl: 'http://api'))
      ..httpClientAdapter = FakeAdapter(handler);

void main() {
  group(App, () {
    testWidgets('signed out: opens on welcome', (tester) async {
      await tester.pumpWidget(
        App(
          config: testConfig,
          dio: _dio((_) async => jsonBody(200, null)),
          tokenStore: FakeTokenStore(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('stored login: opens on the account', (tester) async {
      final store = FakeTokenStore(
        StoredSession(
          accessToken: 'a',
          refreshToken: 'r',
          accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
          accountJson: meJson(name: 'Asha'),
        ),
      );
      await tester.pumpWidget(
        App(
          config: testConfig,
          dio: _dio((_) async => jsonBody(200, meJson(name: 'Asha'))),
          tokenStore: store,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AccountPage), findsOneWidget);
      expect(find.text('HELLO, ASHA'), findsOneWidget);
    });

    testWidgets('logging in moves to the account; out moves back', (
      tester,
    ) async {
      final store = FakeTokenStore();
      await tester.pumpWidget(
        App(
          config: testConfig,
          dio: _dio(
            (o) async => switch (o.path) {
              '/auth/login' => jsonBody(200, {
                'user': meJson(name: 'Asha'),
                'tokens': tokensJson(),
              }),
              _ => jsonBody(204, null),
            },
          ),
          tokenStore: store,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('welcome_log_in')));
      await tester.pumpAndSettle();
      Finder input(String key) => find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      );
      await tester.enterText(input('login_email'), 'asha@example.com');
      await tester.enterText(input('login_password_input'), 'secret');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();
      expect(find.byType(AccountPage), findsOneWidget);
      expect(store.session, isA<StoredSession>());

      await tester.tap(find.byKey(const Key('account_log_out')));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(store.session, isNull);
    });
  });
}
