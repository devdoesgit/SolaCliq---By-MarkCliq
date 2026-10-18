import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/health/health.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Every design-system component, for checking them on a real screen.
/// Development flavor only. All data here is illustrative and stays in this
/// file rather than the ARB, since it never reaches users.
class GalleryPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: SolaText(l10n.galleryTitle, style: SolaTextStyle.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: SolaSpace.space12),
        children: [
          SolaNotice(
            title: l10n.illustrative,
            body: 'Names, amounts and dates on this screen are not real.',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              SolaSpace.space6,
              SolaSpace.space6,
              SolaSpace.space6,
              0,
            ),
            child: HealthStatus(),
          ),
          const _Section(title: 'Buttons', child: _Buttons()),
          const _Section(title: 'Text fields', child: _TextFields()),
          const _Section(title: 'Status pills', child: _Pills()),
          _Section(
            title: 'Stage tracker',
            padded: false,
            child: SolaStageTracker(
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
                const SolaStage(
                  name: 'Install',
                  state: SolaStageState.upcoming,
                ),
                const SolaStage(
                  name: 'Net metering',
                  state: SolaStageState.upcoming,
                ),
                const SolaStage(
                  name: 'Service',
                  state: SolaStageState.upcoming,
                ),
              ],
            ),
          ),
          const _Section(title: 'List rows', padded: false, child: _Rows()),
          const _Section(title: 'Amounts', child: _Amounts()),
          const _Section(title: 'Notices', padded: false, child: _Notices()),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.title, required this.child, this.padded = true});

  final String title;
  final Widget child;

  /// Full-bleed components (rows, notices) handle their own gutter.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    const gutter = EdgeInsets.symmetric(horizontal: SolaSpace.space6);
    return Padding(
      padding: const EdgeInsets.only(top: SolaSpace.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: gutter,
            child: SolaText(title, style: SolaTextStyle.h2),
          ),
          const SizedBox(height: SolaSpace.space4),
          if (padded) Padding(padding: gutter, child: child) else child,
        ],
      ),
    );
  }
}

void _tapped(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('Tapped: $what')));
}

class _Buttons extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SolaSpace.space3,
      children: [
        SolaButton(
          key: const Key('gallery_button_primary'),
          label: 'Save expense',
          variant: SolaButtonVariant.primary,
          onPressed: () => _tapped(context, 'Save expense'),
        ),
        SolaButton(
          key: const Key('gallery_button_secondary'),
          label: 'Add photo',
          onPressed: () => _tapped(context, 'Add photo'),
        ),
        SolaButton(
          key: const Key('gallery_button_ghost'),
          label: 'Cancel',
          variant: SolaButtonVariant.ghost,
          onPressed: () => _tapped(context, 'Cancel'),
        ),
        SolaButton(
          key: const Key('gallery_button_danger'),
          label: 'Delete receipt',
          variant: SolaButtonVariant.danger,
          onPressed: () => _tapped(context, 'Delete receipt'),
        ),
        const SolaButton(
          key: Key('gallery_button_disabled'),
          label: 'Submit (disabled)',
          onPressed: null,
        ),
        SolaButton(
          key: const Key('gallery_button_full_width'),
          label: 'Mark installed',
          variant: SolaButtonVariant.primary,
          expand: true,
          onPressed: () => _tapped(context, 'Mark installed'),
        ),
      ],
    );
  }
}

class _TextFields extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space6,
      children: [
        SolaTextField(
          key: Key('gallery_field_name'),
          label: 'Customer name',
          hint: 'Full name',
          help: 'As on the electricity bill',
          textInputAction: TextInputAction.next,
        ),
        SolaTextField(
          key: Key('gallery_field_amount'),
          label: 'Amount',
          hint: '0.00',
          numeric: true,
          textInputAction: TextInputAction.next,
        ),
        SolaTextField(
          key: Key('gallery_field_meter'),
          label: 'Meter number',
          error: 'Enter the meter number.',
        ),
      ],
    );
  }
}

class _Pills extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
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
    );
  }
}

class _Rows extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SolaColors.line)),
      ),
      child: Column(
        children: [
          SolaListRow(
            key: const Key('gallery_row_1'),
            title: 'Asha Example (illustrative), 5 kW rooftop',
            meta: 'Quote · 18 Oct 2026',
            semanticsLabel:
                'Asha Example (illustrative), 5 kW rooftop, quote, '
                '${formatPaise(18500000)}, pending',
            onTap: () => _tapped(context, 'Asha Example (illustrative)'),
            trailing: const [
              SolaAmount(18500000),
              SolaStatusPill(label: 'Pending', tone: SolaTone.info),
            ],
          ),
          SolaListRow(
            key: const Key('gallery_row_2'),
            title: 'Sunita Mohanty, 3.3 kW rooftop',
            meta: 'Install · 12 Oct 2026',
            semanticsLabel:
                'Sunita Mohanty, 3.3 kW rooftop, install, '
                '${formatPaise(9800000)}, approved',
            onTap: () => _tapped(context, 'Sunita Mohanty'),
            trailing: const [
              SolaAmount(9800000),
              SolaStatusPill(label: 'Approved', tone: SolaTone.success),
            ],
          ),
          const SolaListRow(
            title: 'Static row, not tappable',
            meta: 'Service · 1 Sep 2026',
          ),
        ],
      ),
    );
  }
}

class _Amounts extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SolaText('Balance due', style: SolaTextStyle.label),
        SizedBox(height: SolaSpace.space1),
        SolaAmount(4250000, tone: SolaAmountTone.due, large: true),
        SizedBox(height: SolaSpace.space6),
        SolaAmountSummary(
          lines: [
            SolaSummaryLine('Panels and inverter', 21000000),
            SolaSummaryLine('Installation', 2500000),
            SolaSummaryLine('Subsidy', 7800000, tone: SolaAmountTone.credit),
          ],
          total: SolaSummaryLine('Total', 15700000),
        ),
      ],
    );
  }
}

class _Notices extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Column(
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
            key: const Key('gallery_notice_retry'),
            label: 'Retry',
            onPressed: () => _tapped(context, 'Retry'),
          ),
        ),
        const SolaNotice(
          title: 'Upload failed',
          body: 'Check your connection and try again.',
          tone: SolaTone.danger,
        ),
        const SolaNotice(title: 'Expense approved', tone: SolaTone.success),
      ],
    );
  }
}
