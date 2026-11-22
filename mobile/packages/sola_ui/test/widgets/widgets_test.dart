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

  group(SolaLinkText, () {
    Widget link(VoidCallback onTap) => SolaLinkText(
      key: const ValueKey('login_create_account'),
      before: 'New to SolaCliq? ',
      link: 'Create account',
      onTap: onTap,
    );

    testWidgets('is one named button that tools can find', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, link(() {}));
      expect(
        tester.getSemantics(find.byKey(const ValueKey('login_create_account'))),
        matchesSemantics(
          label: 'New to SolaCliq? Create account',
          identifier: 'login_create_account',
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the whole line is a 48-tall target', (tester) async {
      var taps = 0;
      await _pump(tester, link(() => taps++));
      final box = tester.getSize(find.byType(SolaLinkText));
      expect(box.height, greaterThanOrEqualTo(48));
      // The words before the link work too.
      await tester.tap(find.byType(SolaLinkText), warnIfMissed: false);
      expect(taps, 1);
    });
  });

  testWidgets('SolaCodeInput is a named field tools can find', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      SolaCodeInput(
        key: const ValueKey('verify_code'),
        label: 'Code',
        controller: controller,
      ),
    );
    expect(find.bySemanticsIdentifier('verify_code'), findsOneWidget);
    expect(find.bySemanticsLabel('Code'), findsWidgets);
    handle.dispose();
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

  testWidgets('SolaValueRow without a value reads its placeholder and error', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      SolaValueRow(
        key: const Key('state'),
        label: 'State',
        placeholder: 'Choose',
        error: 'Choose one.',
        onTap: () {},
      ),
    );
    expect(find.bySemanticsLabel('State: Choose. Choose one.'), findsOne);
    handle.dispose();
  });
}
