import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/legal/legal.dart';
import 'package:solacliq/legal/view/terms_page.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';

import '../helpers/helpers.dart';

void main() {
  late MockAuthRepository auth;
  late MockWorkspaceCubit workspace;

  setUp(() {
    auth = MockAuthRepository();
    workspace = MockWorkspaceCubit();
  });

  Future<void> pump(WidgetTester tester, {int? accepted}) async {
    when(() => workspace.state).thenReturn(
      WorkspaceNeedsTerms(
        testAccount(termsAccepted: accepted, termsCurrent: 2),
      ),
    );
    await tester.pumpApp(
      const TermsPage(),
      authRepository: auth,
      workspaceCubit: workspace,
    );
  }

  group(TermsPage, () {
    testWidgets('continue without ticking says so and sends nothing', (
      tester,
    ) async {
      await pump(tester);
      await tester.tapKey('terms_continue');
      await tester.pump();
      expect(find.text('Tick to agree to continue.'), findsOneWidget);
      verifyNever(() => auth.acceptTerms());
    });

    testWidgets('ticked: records the agreement', (tester) async {
      when(() => auth.acceptTerms()).thenAnswer((_) async {});
      await pump(tester);
      await tester.tapKey('terms_agree');
      await tester.tapKey('terms_continue');
      await tester.pumpAndSettle();
      verify(() => auth.acceptTerms()).called(1);
    });

    testWidgets('first time: worded as before you start', (tester) async {
      await pump(tester);
      expect(find.text('Before you start'), findsOneWidget);
      expect(find.textContaining("We've updated"), findsNothing);
      expect(find.byKey(const Key('log_out')), findsOneWidget);
    });

    testWidgets('agreed to an older version: says the terms changed', (
      tester,
    ) async {
      await pump(tester, accepted: 1);
      expect(find.textContaining("We've updated"), findsOneWidget);
    });
  });

  group(LegalPage, () {
    test('pages are on the website', () {
      final config = AppConfig.production();
      expect(
        LegalPage.terms.url(config).toString(),
        'https://solacliq.markcliq.com/terms',
      );
      expect(
        LegalPage.privacy.url(config).toString(),
        'https://solacliq.markcliq.com/privacy',
      );
      expect(
        LegalPage.companyTerms.url(config).toString(),
        'https://solacliq.markcliq.com/company-terms',
      );
    });
  });
}
