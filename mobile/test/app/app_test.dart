import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:solacliq/app/app.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/welcome_page.dart';
import 'package:solacliq/home/view/home_page.dart';

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
          workspaceStore: FakeWorkspaceStore(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('stored login: opens on the home', (tester) async {
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
          workspaceStore: FakeWorkspaceStore(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_get_quote')), findsOneWidget);
    });

    testWidgets('logging in moves home; out moves back', (tester) async {
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
          workspaceStore: FakeWorkspaceStore(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('welcome_get_started')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('intro_skip')));
      await tester.pumpAndSettle();
      Finder input(String key) => find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      );
      await tester.enterText(input('login_email'), 'asha@example.com');
      await tester.enterText(input('login_password'), 'secret');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      expect(store.session, isA<StoredSession>());

      await tester.tap(find.byKey(const Key('home_profile')));
      await tester.pumpAndSettle();
      await tester.tapKey('workspace_log_out');
      await tester.pumpAndSettle();
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(store.session, isNull);
    });

    testWidgets('several companies: opens the first, then the last used', (
      tester,
    ) async {
      final me = meJson(
        name: 'Kiran',
        memberships: [
          membershipJson(role: 'agent'),
          membershipJson(
            orgId: '0192a000-0000-7000-8000-0000000000a2',
            orgName: 'Sample Rooftops',
          ),
        ],
      );
      StoredSession session() => StoredSession(
        accessToken: 'a',
        refreshToken: 'r',
        accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        accountJson: me,
      );
      final workspaces = FakeWorkspaceStore();
      Future<void> open() async {
        await tester.pumpWidget(
          App(
            key: UniqueKey(),
            config: testConfig,
            dio: _dio(
              (o) async => o.path.endsWith('/home')
                  ? jsonBody(200, {
                      'eyebrow': 'Today',
                      'title': o.path.contains('a2') ? 'Rooftops' : 'Agent',
                      'tiles': <Object>[],
                      'list': {'rows': <Object>[]},
                    })
                  : jsonBody(200, me),
            ),
            tokenStore: FakeTokenStore(session()),
            workspaceStore: workspaces,
          ),
        );
        await tester.pumpAndSettle();
      }

      await open();
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_add_customer')), findsOneWidget);

      // The avatar opens the profile, which lists the workspaces.
      await tester.tap(find.byKey(const Key('home_profile')));
      await tester.pumpAndSettle();
      await tester.tapKey('profile_workspaces');
      await tester.pumpAndSettle();
      await tester.tapKey(
        'workspace_0192a000-0000-7000-8000-0000000000a2:worker',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tab_expenses')), findsOneWidget);

      // Next launch goes straight to the same company.
      await open();
      expect(find.text('Rooftops'), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_expenses')), findsOneWidget);
    });
  });
}
