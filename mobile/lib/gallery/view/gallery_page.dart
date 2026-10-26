import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/health/health.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Development only: the iOS v2 components in their states, and the
/// server's health, to check the design system on a real phone. Sample
/// values only.
class GalleryPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const GalleryView();
}

class GalleryView extends StatefulWidget {
  const new({super.key});

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  String _segment = 'Home';
  String? _chip = 'RCC';
  bool _switch = true;
  final _text = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const choices = [SolaChoice('Home', 'Home'), SolaChoice('Farm', 'Farm')];
    return SolaScreen(
      navBar: SolaNavBar(
        leading: const BackTo(fallback: AppRoutes.home),
        title: l10n.openGallery,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SolaSpace.space16,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SolaPill(l10n.illustrative, tone: SolaTone.warning),
          ),
          const HealthStatus(),
          SolaButton(key: const Key('g_sun'), label: 'Sun', onPressed: () {}),
          SolaButton(
            key: const Key('g_dark'),
            label: 'Dark',
            variant: SolaButtonVariant.dark,
            onPressed: () {},
          ),
          SolaButton(
            key: const Key('g_white'),
            label: 'White',
            variant: SolaButtonVariant.white,
            icon: SolaIcons.logOut,
            onPressed: () {},
          ),
          const SolaButton(
            key: Key('g_disabled'),
            label: 'Disabled',
            onPressed: null,
          ),
          SolaSegmented<String>(
            key: const ValueKey('g_segmented'),
            label: 'Segmented',
            choices: choices,
            selected: _segment,
            onChanged: (v) => setState(() => _segment = v),
          ),
          SolaChips<String>(
            key: const ValueKey('g_chips'),
            label: 'Chips',
            choices: const [
              SolaChoice('RCC', 'RCC'),
              SolaChoice('Tin', 'Tin shed'),
            ],
            selected: _chip,
            onChanged: (v) => setState(() => _chip = v),
          ),
          SolaGroup(
            children: [
              SolaFieldRow(
                key: const ValueKey('g_field'),
                label: 'Field',
                controller: _text,
                placeholder: 'Placeholder',
              ),
              const SolaFieldRow(
                key: ValueKey('g_field_error'),
                label: 'With an error',
                error: 'Something is wrong.',
              ),
              SolaToggleRow(
                key: const Key('g_switch'),
                title: 'Toggle',
                value: _switch,
                onChanged: (v) => setState(() => _switch = v),
              ),
            ],
          ),
          SolaCodeInput(
            key: const ValueKey('g_code'),
            label: 'Code',
            controller: _code,
          ),
          const Wrap(
            spacing: SolaSpace.space6,
            runSpacing: SolaSpace.space6,
            children: [
              SolaPill('Done', tone: SolaTone.success, icon: SolaIcons.check),
              SolaPill('Proof due', tone: SolaTone.warning),
              SolaPill('Fix KYC', tone: SolaTone.danger),
              SolaPill('In review'),
              SolaPill('Live', tone: SolaTone.live),
              SolaPill('Worker', tone: SolaTone.dark),
            ],
          ),
          const SolaNotice(title: 'A danger notice', body: 'With a body.'),
          const SolaNotice(title: 'A success notice', tone: SolaTone.success),
          Row(
            spacing: SolaSpace.space12,
            children: [
              const Expanded(
                child: SolaStatTile(
                  label: 'Dark',
                  value: '2',
                  icon: SolaIcons.camera,
                  footer: 'today',
                  dark: true,
                ),
              ),
              Expanded(
                child: SolaStatTile(
                  label: 'Light',
                  value: '1',
                  icon: SolaIcons.receipt,
                  footer: 'sample',
                  avatars: const [SolaAvatar(glyph: SolaGlyph.rupee, size: 26)],
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SolaStepsCard(
            steps: [SolaStep('First', 'Sample'), SolaStep('Second', 'Sample')],
          ),
        ],
      ),
    );
  }
}
