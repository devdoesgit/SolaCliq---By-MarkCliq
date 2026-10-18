import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';

import '../helpers.dart';

void main() {
  const key = Key('amount_field');

  group(SolaTextField, () {
    testWidgets('label, help and field read as one node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpSola(
        const SolaTextField(
          key: key,
          label: 'Amount',
          help: 'In rupees',
          numeric: true,
        ),
      );
      expect(find.text('AMOUNT'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('AMOUNT.*In rupees', dotAll: true)),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('exposes its key as the accessibility identifier', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpSola(const SolaTextField(key: key, label: 'Amount'));
      expect(tester.getSemantics(find.byKey(key)).identifier, 'amount_field');
      handle.dispose();
    });

    testWidgets('error replaces help', (tester) async {
      await tester.pumpSola(
        const SolaTextField(
          key: key,
          label: 'Amount',
          help: 'In rupees',
          error: 'Enter an amount.',
        ),
      );
      expect(find.text('Enter an amount.'), findsOneWidget);
      expect(find.text('In rupees'), findsNothing);
    });

    testWidgets('reports changes and keeps its own text', (tester) async {
      String? last;
      await tester.pumpSola(
        SolaTextField(
          key: key,
          label: 'Amount',
          initialValue: '12',
          onChanged: (v) => last = v,
        ),
      );
      await tester.enterText(find.byType(TextField), '1250');
      expect(last, '1250');
      expect(find.text('1250'), findsOneWidget);
    });

    testWidgets('uses a caller controller without disposing it', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'abc');
      addTearDown(controller.dispose);
      await tester.pumpSola(
        SolaTextField(key: key, label: 'Name', controller: controller),
      );
      expect(find.text('abc'), findsOneWidget);
      await tester.pumpSola(const SizedBox());
      // Still usable: the field didn't dispose it.
      controller.text = 'still alive';
      expect(controller.text, 'still alive');
    });

    testWidgets('field is at least 48dp tall', (tester) async {
      await tester.pumpSola(const SolaTextField(key: key, label: 'Amount'));
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(SolaSize.tapMin),
      );
    });
  });
}
