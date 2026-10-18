import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';

import '../helpers.dart';

void main() {
  group(SolaText, () {
    testWidgets('headings are uppercase and marked as headers', (tester) async {
      await tester.pumpSola(const SolaText('My jobs', style: SolaTextStyle.h1));
      expect(find.text('MY JOBS'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('MY JOBS')),
        matchesSemantics(label: 'MY JOBS', isHeader: true),
      );
    });

    testWidgets('body keeps its case', (tester) async {
      await tester.pumpSola(const SolaText('Take photos.'));
      expect(find.text('Take photos.'), findsOneWidget);
    });
  });

  group(SolaStatusPill, () {
    testWidgets('shows the word in uppercase', (tester) async {
      await tester.pumpSola(
        const SolaStatusPill(label: 'Approved', tone: SolaTone.success),
      );
      expect(find.text('APPROVED'), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  group(SolaStageTracker, () {
    testWidgets('each stage reads its number, state and date', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpSola(
        SolaStageTracker(
          stages: [
            SolaStage(
              name: 'Lead',
              state: SolaStageState.done,
              date: DateTime(2026, 10, 2),
            ),
            SolaStage(
              name: 'Quote',
              state: SolaStageState.current,
              date: DateTime(2026, 10, 18),
            ),
            const SolaStage(name: 'Install', state: SolaStageState.upcoming),
          ],
        ),
      );
      expect(
        find.bySemanticsLabel('Stage 1 of 3: Lead, done, 2 Oct 2026'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Stage 2 of 3: Quote, current, 18 Oct 2026'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Stage 3 of 3: Install, not started'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group(SolaAmount, () {
    testWidgets('formats paise and shows credits as negative', (tester) async {
      await tester.pumpSola(
        const Column(
          children: [
            SolaAmount(18500000),
            SolaAmount(500000, tone: SolaAmountTone.credit),
          ],
        ),
      );
      expect(find.text('₹1,85,000.00'), findsOneWidget);
      expect(find.text('−₹5,000.00'), findsOneWidget);
    });

    testWidgets('summary shows lines and total', (tester) async {
      await tester.pumpSola(
        const SolaAmountSummary(
          lines: [
            SolaSummaryLine('Panels', 12000000),
            SolaSummaryLine('Subsidy', 7800000, tone: SolaAmountTone.credit),
          ],
          total: SolaSummaryLine('Total', 4200000),
        ),
      );
      expect(find.text('Panels'), findsOneWidget);
      expect(find.text('−₹78,000.00'), findsOneWidget);
      expect(find.text('₹42,000.00'), findsOneWidget);
    });
  });

  group(SolaListRow, () {
    const key = Key('customer_row');

    testWidgets('tappable row calls onTap and reads its label', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpSola(
        SolaListRow(
          key: key,
          title: 'Ramesh Sahoo, 5 kW',
          meta: 'Quote',
          semanticsLabel: 'Ramesh Sahoo, 5 kW, quote stage',
          onTap: () => taps++,
          trailing: const [SolaAmount(18500000)],
        ),
      );
      await tester.tap(find.byKey(key));
      expect(taps, 1);
      expect(
        find.bySemanticsLabel('Ramesh Sahoo, 5 kW, quote stage'),
        findsOneWidget,
      );
      handle.dispose();
    });

    test('a tappable row without a Key fails an assert', () {
      expect(
        () => SolaListRow(title: 'x', onTap: () {}, semanticsLabel: 'x'),
        throwsAssertionError,
      );
    });
  });

  group(SolaNotice, () {
    testWidgets('shows title, body and action', (tester) async {
      await tester.pumpSola(
        SolaNotice(
          title: 'No GPS signal',
          body: 'Move into the open and try again.',
          tone: SolaTone.warning,
          action: SolaButton(
            key: const Key('retry_gps'),
            label: 'Retry',
            onPressed: () {},
          ),
        ),
      );
      expect(find.text('No GPS signal'), findsOneWidget);
      expect(find.text('Move into the open and try again.'), findsOneWidget);
      expect(find.byKey(const Key('retry_gps')), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
