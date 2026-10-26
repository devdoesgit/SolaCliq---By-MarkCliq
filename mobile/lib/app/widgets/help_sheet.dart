import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// MarkCliq's public contact details (AGENCY.md), for "Need help?".
abstract final class MarkCliqContact {
  static final Uri whatsApp = Uri.parse('https://wa.me/918288956934');
  static final Uri phone = Uri.parse('tel:+917009213298');
  static final Uri email = Uri.parse('mailto:info@markcliq.com');
}

/// Opens the help sheet: call the person's company when [orgName] and
/// [orgPhone] are known, or WhatsApp, call or email MarkCliq.
Future<void> showHelpSheet(
  BuildContext context, {
  String? orgName,
  String? orgPhone,
}) {
  final l10n = context.l10n;
  Future<void> open(BuildContext sheet, Uri uri) async {
    Navigator.of(sheet).pop();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  SolaListRow row(
    BuildContext sheet,
    String key,
    String title,
    String detail,
    SolaIcons icon,
    Uri uri,
  ) => SolaListRow(
    key: Key(key),
    title: title,
    subtitle: detail,
    leading: SolaAvatar(icon: icon, color: SolaColors.tan),
    trailing: const SolaIcon(
      SolaIcons.chevronRight,
      size: 18,
      color: SolaColors.faint,
    ),
    onTap: () => unawaited(open(sheet, uri)),
  );

  return showSolaSheet<void>(
    context: context,
    title: l10n.needHelp,
    doneLabel: l10n.done2,
    builder: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        SolaText(l10n.helpBody, color: SolaColors.muted),
        if (orgName != null && orgPhone != null)
          SolaGroup(
            children: [
              row(
                sheet,
                'help_call_org',
                l10n.helpCallOrg(orgName),
                l10n.helpCallOrgSub(orgName),
                SolaIcons.phone,
                Uri.parse('tel:+91$orgPhone'),
              ),
            ],
          ),
        SolaGroup(
          children: [
            row(
              sheet,
              'help_whatsapp',
              l10n.helpWhatsApp,
              '+91 82889 56934',
              SolaIcons.chat,
              MarkCliqContact.whatsApp,
            ),
            row(
              sheet,
              'help_call',
              l10n.helpCall,
              '+91 70092 13298',
              SolaIcons.user,
              MarkCliqContact.phone,
            ),
            row(
              sheet,
              'help_email',
              l10n.helpEmail,
              'info@markcliq.com',
              SolaIcons.file,
              MarkCliqContact.email,
            ),
          ],
        ),
      ],
    ),
  );
}
