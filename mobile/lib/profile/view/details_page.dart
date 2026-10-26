import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/profile/data/profile_repository.dart';

/// A worker's phone, address and emergency contact, for their admins.
/// Name and email come from the account and can't change here.
class DetailsPage extends StatefulWidget {
  const new({required this.account, super.key});

  final Account account;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late Future<PersonalDetails> _loaded = _fetch();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _emergency = TextEditingController();
  String? _phoneError;
  String? _error;
  bool _saving = false;
  bool _saved = false;

  Future<PersonalDetails> _fetch() async {
    final d = await context.read<ProfileRepository>().details();
    _phone.text = d.phone ?? widget.account.phone ?? '';
    _address.text = d.address ?? '';
    _emergency.text = d.emergencyContact ?? '';
    return d;
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _emergency.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    context
      ..fillBlank(_address, 'H.No 12, Phase 9, Mohali (illustrative)')
      ..fillBlank(_emergency, 'Kamla Example · 9814055210 (illustrative)');
    final phoneError = AuthValidators.optionalMobile(_phone.text, l10n);
    setState(() {
      _phoneError = phoneError;
      _error = null;
      _saved = false;
    });
    if (phoneError != null) return;
    final repo = context.read<ProfileRepository>();
    setState(() => _saving = true);
    try {
      await repo.saveDetails(
        phone: AuthValidators.digits(_phone.text),
        address: _address.text.trim(),
        emergencyContact: _emergency.text.trim(),
      );
      if (mounted) setState(() => _saved = true);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.code.message(l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = _error;
    return SolaScreen(
      background: SolaBackground.sand,
      navBar: SolaNavBar(
        leading: const BackTo(fallback: AppRoutes.home),
        title: l10n.personalDetails,
      ),
      body: LoadView(
        future: _loaded,
        failedTitle: l10n.detailsLoadFailed,
        onRetry: () => setState(() => _loaded = _fetch()),
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SolaSpace.space14,
          children: [
            SolaGroup(
              children: [
                SolaKeyValueRow(l10n.fullNameLabel, widget.account.name),
                SolaKeyValueRow(l10n.emailLabel, widget.account.email),
              ],
            ),
            SolaGroup(
              children: [
                SolaFieldRow(
                  key: const ValueKey('details_phone'),
                  label: l10n.mobileLabel,
                  controller: _phone,
                  error: _phoneError,
                  prefixText: '+91 ',
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                ),
                SolaFieldRow(
                  key: const ValueKey('details_address'),
                  label: l10n.addressLabel,
                  controller: _address,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.fullStreetAddress],
                ),
                SolaFieldRow(
                  key: const ValueKey('details_emergency'),
                  label: l10n.emergencyContactLabel,
                  controller: _emergency,
                  placeholder: l10n.emergencyPlaceholder,
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
            if (_saved)
              SolaBanner(
                title: l10n.savedTitle,
                body: l10n.detailsSavedBody,
                tone: SolaTone.success,
                icon: SolaIcons.check,
              ),
            if (error != null)
              SolaNotice(
                key: const Key('failure_notice'),
                title: error,
                announce: true,
              ),
          ],
        ),
      ),
      bottom: SolaBottomBar(
        children: [
          SolaButton(
            key: const Key('details_save'),
            label: l10n.saveLabel,
            onPressed: _saving ? null : () => unawaited(_save()),
          ),
        ],
      ),
    );
  }
}
