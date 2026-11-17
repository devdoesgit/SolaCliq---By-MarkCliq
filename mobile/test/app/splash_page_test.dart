import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/view/splash_page.dart';

import '../helpers/helpers.dart';

void main() {
  group(SplashPage, () {
    testWidgets('shows the mark and wordmark as Android draws them, labelled', (
      tester,
    ) async {
      await tester.pumpApp(const SplashPage());
      final mark = find.byType(SolaSplashMark);
      expect(mark, findsOneWidget);
      // Android's splash square, centred on the screen.
      expect(tester.getSize(mark), const Size.square(SolaSplashMark.size));
      expect(tester.getCenter(mark), tester.getCenter(find.byType(SplashPage)));
      expect(find.bySemanticsLabel('SolaCliq'), findsOneWidget);
    });
  });
}
