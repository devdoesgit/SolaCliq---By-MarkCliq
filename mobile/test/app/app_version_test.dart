import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/widgets/app_version.dart';

import '../helpers/helpers.dart';

void main() {
  group(AppVersionFooter, () {
    testWidgets('shows the installed version and the product', (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'SolaCliq',
        packageName: 'com.markcliq.solacliq',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      await tester.pumpApp(const AppVersionFooter());
      await tester.pump();
      expect(find.text('v1.0.0 ·'), findsOneWidget);
      expect(find.byType(SolaWordmark), findsOneWidget);
      expect(find.text('by MarkCliq'), findsOneWidget);
      // Read out as one line.
      expect(
        find.bySemanticsLabel('v1.0.0 · SolaCliq by MarkCliq'),
        findsOneWidget,
      );
    });
  });
}
