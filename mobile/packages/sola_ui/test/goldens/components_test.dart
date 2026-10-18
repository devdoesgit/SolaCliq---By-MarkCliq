// Golden images of every component and state. Text renders as blocks (the
// test font), so these catch layout, colour and spacing changes, not glyphs.
// Update with: flutter test --update-goldens
@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';

Future<void> _golden(
  WidgetTester tester,
  String name,
  Widget child, {
  double height = 640,
}) async {
  tester.view
    ..physicalSize = Size(360, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SolaTheme.light(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(SolaSpace.space4),
          child: child,
        ),
      ),
    ),
  );
  await expectLater(find.byType(Scaffold), matchesGoldenFile('$name.png'));
}

void main() {
  testWidgets('button', (tester) async {
    await _golden(
      tester,
      'button',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: SolaSpace.space3,
        children: [
          SolaButton(
            key: const Key('p'),
            label: 'Save expense',
            variant: SolaButtonVariant.primary,
            onPressed: () {},
          ),
          SolaButton(key: const Key('s'), label: 'Add photo', onPressed: () {}),
          SolaButton(
            key: const Key('g'),
            label: 'Cancel',
            variant: SolaButtonVariant.ghost,
            onPressed: () {},
          ),
          SolaButton(
            key: const Key('d'),
            label: 'Delete',
            variant: SolaButtonVariant.danger,
            onPressed: () {},
          ),
          const SolaButton(key: Key('x'), label: 'Disabled', onPressed: null),
          SolaButton(
            key: const Key('e'),
            label: 'Mark installed',
            variant: SolaButtonVariant.primary,
            expand: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  });

  testWidgets('text field', (tester) async {
    await _golden(
      tester,
      'text_field',
      const Column(
        spacing: SolaSpace.space6,
        children: [
          SolaTextField(
            key: Key('a'),
            label: 'Customer name',
            hint: 'Full name',
            help: 'As on the electricity bill',
          ),
          SolaTextField(
            key: Key('b'),
            label: 'Amount',
            initialValue: '1250',
            numeric: true,
          ),
          SolaTextField(
            key: Key('c'),
            label: 'Meter number',
            error: 'Enter the meter number.',
          ),
        ],
      ),
    );
  });

  testWidgets('status pill', (tester) async {
    await _golden(
      tester,
      'status_pill',
      const Wrap(
        spacing: SolaSpace.space2,
        runSpacing: SolaSpace.space2,
        children: [
          SolaStatusPill(label: 'Draft'),
          SolaStatusPill(label: 'Approved', tone: SolaTone.success),
          SolaStatusPill(label: 'Flagged', tone: SolaTone.warning),
          SolaStatusPill(label: 'Rejected', tone: SolaTone.danger),
          SolaStatusPill(label: 'Pending', tone: SolaTone.info),
          SolaStatusPill(label: 'Current', tone: SolaTone.accent),
        ],
      ),
    );
  });

  testWidgets('stage tracker', (tester) async {
    await _golden(
      tester,
      'stage_tracker',
      SolaStageTracker(
        stages: [
          SolaStage(
            name: 'Lead',
            state: SolaStageState.done,
            date: DateTime(2026, 10, 2),
          ),
          SolaStage(
            name: 'Site survey',
            state: SolaStageState.done,
            date: DateTime(2026, 10, 9),
          ),
          SolaStage(
            name: 'Quote',
            state: SolaStageState.current,
            date: DateTime(2026, 10, 18),
          ),
          const SolaStage(
            name: 'Subsidy paperwork',
            state: SolaStageState.upcoming,
          ),
          const SolaStage(name: 'Install', state: SolaStageState.upcoming),
        ],
      ),
    );
  });

  testWidgets('list row', (tester) async {
    await _golden(
      tester,
      'list_row',
      Column(
        children: [
          SolaListRow(
            key: const Key('r1'),
            title: 'Ramesh Sahoo, 5 kW rooftop',
            meta: 'Quote · 18 Oct 2026',
            semanticsLabel: 'Ramesh Sahoo',
            onTap: () {},
            trailing: const [
              SolaAmount(18500000),
              SolaStatusPill(label: 'Pending', tone: SolaTone.info),
            ],
          ),
          const SolaListRow(
            title: 'Static row with a long title that wraps onto two lines',
            meta: 'Install',
          ),
        ],
      ),
    );
  });

  testWidgets('amount', (tester) async {
    await _golden(
      tester,
      'amount',
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: SolaSpace.space4,
        children: [
          SolaAmount(4250000, tone: SolaAmountTone.due, large: true),
          SolaAmountSummary(
            lines: [
              SolaSummaryLine('Panels and inverter', 21000000),
              SolaSummaryLine('Installation', 2500000),
              SolaSummaryLine('Subsidy', 7800000, tone: SolaAmountTone.credit),
            ],
            total: SolaSummaryLine('Total', 15700000),
          ),
        ],
      ),
    );
  });

  testWidgets('notice', (tester) async {
    await _golden(
      tester,
      'notice',
      Column(
        spacing: SolaSpace.space3,
        children: [
          const SolaNotice(
            title: 'Waiting for approval',
            body: 'MarkCliq is checking your GSTIN.',
          ),
          SolaNotice(
            title: 'No GPS signal',
            body: 'Move into the open and try again.',
            tone: SolaTone.warning,
            action: SolaButton(
              key: const Key('retry'),
              label: 'Retry',
              onPressed: () {},
            ),
          ),
          const SolaNotice(
            title: 'Upload failed',
            body: 'Check your connection.',
            tone: SolaTone.danger,
          ),
          const SolaNotice(title: 'Expense approved', tone: SolaTone.success),
        ],
      ),
    );
  });
}
