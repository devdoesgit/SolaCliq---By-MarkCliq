import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Why the proof camera reads location, before Android asks. False when
/// they back out: the camera then closes, as it can't take proof.
Future<bool> showLocationNote(BuildContext context) async {
  final l10n = context.l10n;
  final agreed = await showSolaSheet<bool>(
    context: context,
    title: l10n.locationNoteTitle,
    doneLabel: l10n.cancel,
    builder: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        SolaText(l10n.locationNoteBody, color: SolaColors.muted),
        SolaButton(
          key: const Key('location_note_continue'),
          label: l10n.continueAction,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
      ],
    ),
  );
  return agreed ?? false;
}
