import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/legal/legal.dart';

/// What SolaCliq stores and why, links to the Terms of Use and the
/// Privacy Policy, and the tick to agree (F16). The tick starts off; the
/// form refuses to send until it is on ([error] says so).
///
/// With [onCompanyChanged], a second tick for the Company Terms, for a
/// company owner registering.
class TermsAgreement extends StatelessWidget {
  const new({
    required this.value,
    required this.onChanged,
    super.key,
    this.error,
    this.companyValue = false,
    this.onCompanyChanged,
    this.companyError,
  });

  /// Whether the Terms of Use and Privacy Policy are ticked.
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? error;

  /// Whether the Company Terms are ticked; shown only with
  /// [onCompanyChanged].
  final bool companyValue;
  final ValueChanged<bool>? onCompanyChanged;
  final String? companyError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onCompanyChanged = this.onCompanyChanged;

    Widget errorText(String? message) => message == null
        ? const SizedBox.shrink()
        : SolaText(
            message,
            style: SolaTextStyle.meta,
            color: SolaColors.danger,
          );

    Widget link(String key, String document, LegalPage page) => SolaLinkText(
      key: Key(key),
      link: l10n.readDocument(document),
      textAlign: TextAlign.start,
      style: SolaTextStyle.small,
      onTap: () => openLegalPage(context, page),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SolaText(
          l10n.termsNotice,
          style: SolaTextStyle.small,
          color: SolaColors.muted,
        ),
        link('terms_read_terms', l10n.termsOfUse, LegalPage.terms),
        link('terms_read_privacy', l10n.privacyPolicy, LegalPage.privacy),
        if (onCompanyChanged != null)
          link('terms_read_company', l10n.companyTerms, LegalPage.companyTerms),
        SolaGroup(
          children: [
            SolaToggleRow(
              key: const Key('terms_agree'),
              title: l10n.termsAgree,
              value: value,
              onChanged: onChanged,
            ),
            if (onCompanyChanged != null)
              SolaToggleRow(
                key: const Key('terms_agree_company'),
                title: l10n.companyTermsAgree,
                value: companyValue,
                onChanged: onCompanyChanged,
              ),
          ],
        ),
        errorText(error ?? companyError),
      ],
    );
  }
}
