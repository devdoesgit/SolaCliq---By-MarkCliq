import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';

import '../helpers.dart';

void main() {
  group(SolaLockup, () {
    testWidgets('is read out as one line', (tester) async {
      await tester.pumpSola(
        const Align(
          alignment: Alignment.topLeft,
          child: SolaLockup(
            height: 30,
            byline: 'by MarkCliq',
            semanticsLabel: 'SolaCliq · by MarkCliq',
          ),
        ),
      );
      expect(find.bySemanticsLabel('SolaCliq · by MarkCliq'), findsOneWidget);
      expect(find.text('by MarkCliq', findRichText: true), findsOneWidget);
    });

    testWidgets("sets the byline on the wordmark's baseline", (tester) async {
      await tester.pumpSola(
        const Align(
          alignment: Alignment.topLeft,
          child: SolaLockup(height: 30, byline: 'by MarkCliq'),
        ),
      );
      final lockupTop = tester.getTopLeft(find.byType(SolaLockup)).dy;
      final text = tester.renderObject<RenderParagraph>(
        find.text('by MarkCliq', findRichText: true),
      );
      final baseline =
          text.localToGlobal(Offset.zero).dy +
          text.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      expect(
        baseline - lockupTop,
        moreOrLessEquals(30 * 104 / 132, epsilon: 0.5),
      );
    });

    testWidgets('is decorative without a label', (tester) async {
      await tester.pumpSola(
        const Align(
          alignment: Alignment.topLeft,
          child: SolaLockup(height: 30),
        ),
      );
      expect(find.text('by MarkCliq', findRichText: true), findsNothing);
      expect(tester.getSize(find.byType(SolaLockup)).height, 30);
    });
  });

  group(SolaBrandText, () {
    testWidgets('sets "Cliq" in MarkCliq in italic', (tester) async {
      await tester.pumpSola(const SolaBrandText('Secured by MarkCliq'));
      final rich = tester.widget<RichText>(
        find.text('Secured by MarkCliq', findRichText: true),
      );
      final spans = <TextSpan>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
      expect(spans.map((s) => s.text).join(), 'Secured by MarkCliq');
      final cliq = spans.singleWhere((s) => s.text == 'Cliq');
      expect(cliq.style?.fontStyle, FontStyle.italic);
      final mark = spans.singleWhere((s) => s.text == 'Mark');
      expect(mark.style?.fontStyle, isNot(FontStyle.italic));
    });
  });

  group('SolaLockup without the mark', () {
    testWidgets('draws the wordmark alone at its height', (tester) async {
      await tester.pumpSola(
        const Align(
          alignment: Alignment.topLeft,
          child: SolaLockup(height: 26, mark: false, byline: 'by MarkCliq'),
        ),
      );
      final svg = tester.getSize(find.byType(SvgPicture));
      expect(svg.height, 26);
      // Narrower than with the mark.
      expect(svg.width, lessThan(26 * 569.92 / 132));
    });
  });
}
