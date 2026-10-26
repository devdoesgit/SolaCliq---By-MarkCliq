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

    testWidgets('the segmented control switches', (tester) async {
      await tester.pumpApp(const GalleryPage(), healthRepository: health);
      await tester.tapKey('g_segmented_1');
      await tester.pump();
      expect(
        tester.getSemantics(find.byKey(const ValueKey('g_segmented_1'))),
        isSemantics(isSelected: true),
      );
    });
  });
}
