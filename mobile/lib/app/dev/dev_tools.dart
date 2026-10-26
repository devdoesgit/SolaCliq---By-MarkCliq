import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/dev/mock_persona.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Development flavor only: which mock person to play, the prototype's
/// "simulate an invite", and the component gallery. Shown in the workspace
/// sheet, dashed like the prototype controls in the designs.
class DevToolsSection extends StatelessWidget {
  const new({super.key});

  Future<void> _pickPersona(BuildContext context) async {
    final mock = context.read<MockPersonaInterceptor>();
    final auth = context.read<AuthRepository>();
    final picked = await showSolaSheet<(MockPersona?,)>(
      context: context,
      title: 'Mock person',
      doneLabel: context.l10n.done2,
      builder: (sheet) => SolaGroup(
        children: [
          for (final persona in [null, ...MockPersona.values])
            SolaListRow(
              key: Key('dev_persona_${persona?.example ?? 'default'}'),
              title: persona?.example ?? sheet.l10n.devPersonaDefault,
              trailing: persona == mock.persona.value
                  ? const SolaIcon(SolaIcons.check)
                  : null,
              onTap: () => Navigator.of(sheet).pop((persona,)),
            ),
        ],
      ),
    );
    if (picked == null) return;
    // Close the workspace sheet too, if it is open: its options change with
    // the person.
    if (context.mounted) await Navigator.maybePop(context);
    mock.persona.value = picked.$1;
    await auth.refreshAccount(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mock = context.read<MockPersonaInterceptor>();
    final quick = context.read<QuickForms>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space8,
      children: [
        const SizedBox(height: SolaSpace.space8),
        SolaSectionLabel(l10n.devTitle),
        ListenableBuilder(
          listenable: Listenable.merge([
            mock.persona,
            mock.inviteWaiting,
            mock.handedOver,
            quick.enabled,
          ]),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SolaSpace.space8,
            children: [
              _DevButton(
                key: const Key('dev_persona'),
                label: l10n.devPersona(
                  mock.persona.value?.example ?? l10n.devPersonaDefault,
                ),
                onTap: () => unawaited(_pickPersona(context)),
              ),
              _DevButton(
                key: const Key('dev_invite'),
                label: l10n.devInviteWaiting(
                  mock.inviteWaiting.value ? l10n.on : l10n.off,
                ),
                onTap: () =>
                    mock.inviteWaiting.value = !mock.inviteWaiting.value,
              ),
              _DevButton(
                key: const Key('dev_handed_over'),
                label: l10n.devLiveEnergy(
                  mock.handedOver.value ? l10n.on : l10n.off,
                ),
                onTap: () => mock.handedOver.value = !mock.handedOver.value,
              ),
              _DevButton(
                key: const Key('dev_quick_forms'),
                label: l10n.devQuickForms(
                  quick.enabled.value ? l10n.on : l10n.off,
                ),
                onTap: () => quick.enabled.value = !quick.enabled.value,
              ),
            ],
          ),
        ),
        _DevButton(
          key: const Key('dev_gallery'),
          label: l10n.openGallery,
          onTap: () => unawaited(context.push(AppRoutes.gallery)),
        ),
      ],
    );
  }
}

/// An outlined uppercase pill: prototype controls, as the designs draw them.
class _DevButton extends StatelessWidget {
  const new({required Key super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SolaTappable(
      identifier: semanticsIdentifier(key),
      semanticsLabel: label,
      onTap: onTap,
      builder: (context, state) => Container(
        height: 34,
        decoration: BoxDecoration(
          color: state.pressed ? SolaColors.tan : null,
          borderRadius: BorderRadius.circular(SolaRadius.radiusPill),
          border: Border.all(color: SolaColors.dashed),
        ),
        child: Center(
          child: SolaText(
            label,
            style: SolaTextStyle.eyebrow,
            color: SolaColors.muted,
          ),
        ),
      ),
    );
  }
}
