import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/gallery/view/gallery_page.dart';
import 'package:solacliq/health/health.dart';

import '../helpers/helpers.dart';

void main() {
  late MockHealthRepository health;

  setUp(() {
    health = MockHealthRepository();
    when(() => health.fetch(cancelToken: any(named: 'cancelToken'))).thenAnswer(
      (_) async => const HealthReport(databaseOk: true, version: '0.1.0'),
    );
  });

  group(GalleryPage, () {
    testWidgets('is labelled illustrative', (tester) async {
      await tester.pumpApp(const GalleryPage(), healthRepository: health);
      expect(find.text('Illustrative'), findsOneWidget);
    });

    testWidgets('every tap target meets the size and label guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const GalleryPage(), healthRepository: health);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('tapping a button confirms it', (tester) async {
      await tester.pumpApp(const GalleryPage(), healthRepository: health);
      await tester.tap(find.byKey(const Key('gallery_button_primary')));
      await tester.pump();
      expect(find.text('Tapped: Save expense'), findsOneWidget);
    });
  });
}
