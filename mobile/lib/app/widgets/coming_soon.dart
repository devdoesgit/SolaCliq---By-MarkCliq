import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Says a part of the app isn't built yet, for tabs the designs show ahead
/// of their feature.
Future<void> showComingSoon(BuildContext context, String title) {
  final l10n = context.l10n;
  return showSolaSheet<void>(
    context: context,
    title: title,
    doneLabel: l10n.done2,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.only(bottom: SolaSpace.space8),
      child: SolaText(
        l10n.comingSoonBody,
        style: SolaTextStyle.bodyLg,
        color: SolaColors.muted,
      ),
    ),
  );
}
