import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: SolaTheme.light(),
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group(SolaFieldRow, () {
    testWidgets('the prefix shows before anything is typed', (tester) async {
      await _pump(
        tester,
        const SolaFieldRow(
          key: ValueKey('mobile'),
          label: 'Mobile',
          prefixText: '+91 ',
        ),
      );
      expect(find.text('+91 '), findsOneWidget);
    });

    testWidgets('the whole row is the input target', (tester) async {
      await _pump(
        tester,
        const SolaFieldRow(key: ValueKey('name'), label: 'Name'),
      );
      final input = tester.getSize(find.byKey(const ValueKey('name_input')));
      expect(input.height, greaterThanOrEqualTo(48));
    });
  });

  testWidgets('SolaChips reports the chosen value', (tester) async {
    String? chosen;
    await _pump(
      tester,
      SolaChips<String>(
        key: const ValueKey('roof'),
        label: 'Roof',
        choices: const [SolaChoice('rcc', 'RCC'), SolaChoice('tin', 'Tin')],
        selected: 'rcc',
        onChanged: (v) => chosen = v,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('roof_1')));
    expect(chosen, 'tin');
  });

  testWidgets('SolaAvatarStack takes the width it draws', (tester) async {
    await _pump(
      tester,
      const SolaAvatarStack(
        ring: SolaColors.surface,
        avatars: [
          SolaAvatar(initials: 'A', size: 26),
          SolaAvatar(initials: 'B', size: 26),
          SolaAvatar(initials: 'C', size: 26),
        ],
      ),
    );
    expect(tester.getSize(find.byType(SolaAvatarStack)).width, 26 + 21 * 2);
  });

  test('formatDayMonth leaves out the year', () {
    expect(formatDayMonth(DateTime(2026, 10, 23)), '23 Oct');
  });
}
