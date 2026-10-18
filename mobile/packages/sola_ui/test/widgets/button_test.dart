import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';

import '../helpers.dart';

void main() {
  const key = Key('save_expense');

  group(SolaButton, () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpSola(
        Center(
          child: SolaButton(
            key: key,
            label: 'Save expense',
            onPressed: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byKey(key));
      expect(taps, 1);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpSola(
        const Center(
          child: SolaButton(key: key, label: 'Save expense', onPressed: null),
        ),
      );
      await tester.tap(find.byKey(key));
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Save expense',
          isButton: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('is at least 48dp in both directions', (tester) async {
      await tester.pumpSola(
        Center(
          child: SolaButton(key: key, label: 'OK', onPressed: () {}),
        ),
      );
      final size = tester.getSize(find.byKey(key));
      expect(size.height, greaterThanOrEqualTo(SolaSize.tapMin));
      expect(size.width, greaterThanOrEqualTo(SolaSize.tapMin));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('expand fills the width', (tester) async {
      await tester.pumpSola(
        SolaButton(
          key: key,
          label: 'Save expense',
          onPressed: () {},
          expand: true,
        ),
      );
      expect(tester.getSize(find.byKey(key)).width, 800 - 32);
    });

    testWidgets('reads its semanticsLabel', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpSola(
        Center(
          child: SolaButton(
            key: key,
            label: 'Delete',
            semanticsLabel: 'Delete receipt 2',
            onPressed: () {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('Delete receipt 2'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('exposes its key as the accessibility identifier', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpSola(
        Center(
          child: SolaButton(key: key, label: 'Go', onPressed: () {}),
        ),
      );
      expect(tester.getSemantics(find.byKey(key)).identifier, 'save_expense');
      handle.dispose();
    });

    testWidgets('activates from the keyboard', (tester) async {
      var taps = 0;
      await tester.pumpSola(
        Center(
          child: SolaButton(key: key, label: 'Go', onPressed: () => taps++),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('primary text meets contrast guidelines', (tester) async {
      await tester.pumpSola(
        Center(
          child: SolaButton(
            key: key,
            label: 'Save expense',
            variant: SolaButtonVariant.primary,
            onPressed: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
