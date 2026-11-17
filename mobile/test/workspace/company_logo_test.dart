import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/home/view/home_header.dart';
import 'package:solacliq/workspace/data/workspace.dart';
import 'package:solacliq/workspace/view/company_logo.dart';

import '../helpers/helpers.dart';

const _logo = 'https://r2.invalid/orgs/o1/logo/u1?X-Amz-Signature=a';

void main() {
  group(CompanyBadge, () {
    testWidgets('shows the initials when the company has no logo', (
      tester,
    ) async {
      await tester.pumpApp(
        CompanyBadge(
          workspace: MemberWorkspace(testMembership(orgName: 'RY Enterprises')),
        ),
      );
      expect(find.text('RE'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('shows the logo when there is one', (tester) async {
      await tester.pumpApp(
        CompanyBadge(
          workspace: MemberWorkspace(testMembership(orgLogoUrl: _logo)),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, LogoImage(_logo));
    });

    testWidgets('falls back to the initials when the logo fails to load', (
      tester,
    ) async {
      final badge = CompanyBadge(
        workspace: MemberWorkspace(
          testMembership(orgName: 'RY Enterprises', orgLogoUrl: _logo),
        ),
      );
      await tester.pumpApp(badge);
      final image = tester.widget<Image>(find.byType(Image));
      final fallback = image.errorBuilder!(
        tester.element(find.byType(Image)),
        Exception('offline'),
        null,
      );
      expect(fallback, isA<SolaAvatar>());
    });
  });

  group(LogoImage, () {
    test('is cached by the path, not the signature', () {
      expect(
        LogoImage(_logo),
        LogoImage('https://r2.invalid/orgs/o1/logo/u1?X-Amz-Signature=b'),
      );
      expect(
        LogoImage(_logo),
        isNot(
          LogoImage('https://r2.invalid/orgs/o1/logo/u2?X-Amz-Signature=a'),
        ),
      );
    });
  });

  group(HomeHeader, () {
    testWidgets('shows the company logo above the titles', (tester) async {
      await tester.pumpApp(
        const HomeHeader(
          initials: 'RA',
          eyebrow: 'Wednesday, 18 Nov',
          title: 'Ravi',
          logoUrl: _logo,
        ),
      );
      expect(find.byType(CompanyLogo), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(CompanyLogo)).dy,
        lessThan(tester.getTopLeft(find.text('Ravi')).dy),
      );
    });

    testWidgets('shows where the person is, without switching from here', (
      tester,
    ) async {
      await tester.pumpApp(
        const HomeHeader(
          initials: 'RA',
          title: 'Ravi',
          workspaceLine: 'RY Enterprises · EPC Installer',
          onAvatar: _noop,
        ),
      );
      expect(find.text('RY Enterprises · EPC Installer'), findsOneWidget);
      expect(find.byKey(const Key('home_workspace_line')), findsNothing);
    });

    testWidgets('has no logo when the company has none', (tester) async {
      await tester.pumpApp(
        const HomeHeader(initials: 'RA', eyebrow: 'Today', title: 'Ravi'),
      );
      expect(find.byType(CompanyLogo), findsNothing);
    });
  });
}

void _noop() {}
