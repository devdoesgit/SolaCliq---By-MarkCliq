import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/access/data/company_registration_repository.dart';
import 'package:solacliq/access/data/gstin.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/auth/widgets/failure_notice.dart';
import 'package:solacliq/l10n/l10n.dart';

/// A solar company registers with SolaCliq: the owner, then the company
/// as on its GST certificate. The server saves it as pending; MarkCliq
/// checks it, calls them and approves it. Their admin works on the web.
class RequestAccessPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmitCubit(),
      child: const RequestAccessView(),
    );
  }
}

class RequestAccessView extends StatefulWidget {
  const new({super.key});

  @override
  State<RequestAccessView> createState() => _RequestAccessViewState();
}

class _RequestAccessViewState extends State<RequestAccessView> {
  final _owner = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _gstin = TextEditingController();
  final _legalName = TextEditingController();
  final _tradeName = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _pin = TextEditingController();
  BusinessType? _businessType;
  final _errors = <String, String?>{};

  static final _pinPattern = RegExp(r'^[1-9]\d{5}$');

  List<TextEditingController> get _controllers => [
    _owner,
    _email,
    _phone,
    _gstin,
    _legalName,
    _tradeName,
    _address1,
    _address2,
    _city,
    _pin,
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _edited(String field) {
    context.read<SubmitCubit>().reset();
    if (_errors[field] != null) setState(() => _errors[field] = null);
  }

  /// Text with spaces trimmed; null when blank (an optional field left out).
  static String? _optional(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    context
      ..fillBlank(_owner, 'Ravi Example')
      ..fillBlank(_email, 'ravi@example.com')
      ..fillBlank(_phone, '98765 43210')
      ..fillBlank(_gstin, '27AAPFU0939F1ZV')
      ..fillBlank(_legalName, 'Sample Solar Private Limited (illustrative)')
      ..fillBlank(_address1, 'Plot 4, MIDC')
      ..fillBlank(_city, 'Pune')
      ..fillBlank(_pin, '411001');
    if (context.quickForms) _businessType ??= BusinessType.privateLimited;

    final l10n = context.l10n;
    final gstin = Gstin.tryParse(_gstin.text);
    setState(() {
      _errors
        ..['owner'] = AuthValidators.required(_owner.text, l10n.fieldName, l10n)
        ..['email'] = AuthValidators.email(_email.text.trim(), l10n)
        ..['phone'] = AuthValidators.mobile(_phone.text, l10n)
        ..['gstin'] = gstin == null ? l10n.errorGstin : null
        ..['legalName'] = AuthValidators.required(
          _legalName.text,
          l10n.fieldLegalName,
          l10n,
        )
        ..['businessType'] = _businessType == null
            ? l10n.errorRequired(l10n.fieldBusinessType)
            : null
        ..['address1'] = AuthValidators.required(
          _address1.text,
          l10n.fieldAddress,
          l10n,
        )
        ..['city'] = AuthValidators.required(_city.text, l10n.fieldCity, l10n)
        ..['pin'] = _pinPattern.hasMatch(_pin.text.trim())
            ? null
            : l10n.errorPinCode;
    });
    final businessType = _businessType;
    if (_errors.values.any((e) => e != null) ||
        gstin == null ||
        businessType == null) {
      return;
    }

    final registrations = context.read<CompanyRegistrationRepository>();
    await context.read<SubmitCubit>().submit(
      () => registrations.register(
        CompanyRegistration(
          ownerName: _owner.text.trim(),
          email: _email.text.trim(),
          phone: AuthValidators.digits(_phone.text),
          gstin: gstin.number,
          legalName: _legalName.text.trim(),
          tradeName: _optional(_tradeName),
          businessType: businessType,
          addressLine1: _address1.text.trim(),
          addressLine2: _optional(_address2),
          city: _city.text.trim(),
          pinCode: _pin.text.trim(),
        ),
      ),
    );
  }

  Future<void> _pickBusinessType() async {
    final l10n = context.l10n;
    final picked = await showSolaSheet<BusinessType>(
      context: context,
      title: l10n.fieldBusinessType,
      doneLabel: l10n.cancel,
      builder: (sheet) => SolaGroup(
        children: [
          for (final type in BusinessType.values)
            SolaListRow(
              key: ValueKey('business_type_${type.name}'),
              title: type.label(l10n),
              trailing: type == _businessType
                  ? const SolaIcon(SolaIcons.check)
                  : null,
              onTap: () => Navigator.of(sheet).pop(type),
            ),
        ],
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _businessType = picked;
        _errors['businessType'] = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = Gstin.tryParse(_gstin.text)?.state;
    return BlocConsumer<SubmitCubit, SubmitState>(
      listenWhen: (a, b) => b.status == SubmitStatus.success,
      listener: (context, _) => context.pushReplacement(
        AppRoutes.requestSentTo(
          company: _optional(_tradeName) ?? _legalName.text.trim(),
          email: _email.text.trim(),
        ),
      ),
      builder: (context, submit) => SolaScreen(
        navBar: const SolaNavBar(leading: BackTo(fallback: AppRoutes.welcome)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: SolaSpace.space14),
            SolaText(
              l10n.requestEyebrow,
              style: SolaTextStyle.eyebrow,
              color: SolaColors.tanText,
            ),
            const SizedBox(height: SolaSpace.space8),
            SolaTitleBlock(
              title: l10n.requestTitle,
              subtitle: l10n.requestBody,
            ),
            const SizedBox(height: SolaSpace.space22),
            if (submit.status == SubmitStatus.failure) ...[
              FailureNotice(state: submit),
              const SizedBox(height: SolaSpace.space14),
            ],
            SolaSectionLabel(l10n.sectionAboutYou),
            const SizedBox(height: SolaSpace.space8),
            SolaGroup(
              children: [
                SolaFieldRow(
                  key: const ValueKey('access_owner'),
                  label: l10n.fieldName,
                  controller: _owner,
                  error: _errors['owner'],
                  placeholder: l10n.fullNamePlaceholder,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  onChanged: (_) => _edited('owner'),
                ),
                SolaFieldRow(
                  key: const ValueKey('access_email'),
                  label: l10n.fieldWorkEmail,
                  controller: _email,
                  error: _errors['email'],
                  placeholder: l10n.workEmailPlaceholder,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  onChanged: (_) => _edited('email'),
                ),
                SolaFieldRow(
                  key: const ValueKey('access_phone'),
                  label: l10n.fieldPhone,
                  controller: _phone,
                  error: _errors['phone'],
                  prefixText: '+91 ',
                  placeholder: l10n.phonePlaceholder,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                    LengthLimitingTextInputFormatter(11),
                  ],
                  onChanged: (_) => _edited('phone'),
                ),
              ],
            ),
            const SizedBox(height: SolaSpace.space22),
            SolaSectionLabel(l10n.sectionYourCompany),
            const SizedBox(height: SolaSpace.space8),
            SolaGroup(
              children: [
                SolaFieldRow(
                  key: const ValueKey('access_gstin'),
                  label: l10n.fieldGstin,
                  controller: _gstin,
                  error: _errors['gstin'],
                  placeholder: l10n.gstinPlaceholder,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9A-Za-z ]')),
                    LengthLimitingTextInputFormatter(17),
                  ],
                  // Rebuilds so the state row follows the GSTIN.
                  onChanged: (_) => setState(() => _edited('gstin')),
                ),
                SolaValueRow(
                  key: const Key('access_state'),
                  label: l10n.fieldState,
                  value: state ?? l10n.stateFromGstin,
                ),
                SolaFieldRow(
                  key: const ValueKey('access_legal_name'),
                  label: l10n.fieldLegalName,
                  controller: _legalName,
                  error: _errors['legalName'],
                  placeholder: l10n.legalNamePlaceholder,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.organizationName],
                  onChanged: (_) => _edited('legalName'),
                ),
                SolaFieldRow(
                  key: const ValueKey('access_trade_name'),
                  label: l10n.fieldTradeName,
                  controller: _tradeName,
                  placeholder: l10n.tradeNamePlaceholder,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _edited('tradeName'),
                ),
                SolaValueRow(
                  key: const Key('access_business_type'),
                  label: l10n.fieldBusinessType,
                  value: _businessType?.label(l10n) ?? l10n.chooseBusinessType,
                  error: _errors['businessType'],
                  onTap: () => unawaited(_pickBusinessType()),
                ),
              ],
            ),
            const SizedBox(height: SolaSpace.space14),
            SolaGroup(
              children: [
                SolaFieldRow(
                  key: const ValueKey('access_address1'),
                  label: l10n.fieldAddress,
                  controller: _address1,
                  error: _errors['address1'],
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.streetAddressLine1],
                  onChanged: (_) => _edited('address1'),
                ),
                SolaFieldRow(
                  key: const ValueKey('access_address2'),
                  label: l10n.fieldAddressLine2,
                  controller: _address2,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.streetAddressLine2],
                  onChanged: (_) => _edited('address2'),
                ),
                SolaFieldRow(
                  key: const ValueKey('access_city'),
                  label: l10n.fieldCity,
                  controller: _city,
                  error: _errors['city'],
                  placeholder: l10n.cityPlaceholder,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.addressCity],
                  onChanged: (_) => _edited('city'),
                ),
                SolaFieldRow(
                  key: const ValueKey('access_pin'),
                  label: l10n.fieldPinCode,
                  controller: _pin,
                  error: _errors['pin'],
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.postalCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) => unawaited(_submit()),
                  onChanged: (_) => _edited('pin'),
                ),
              ],
            ),
          ],
        ),
        bottom: SolaBottomBar(
          children: [
            SolaButton(
              key: const Key('access_submit'),
              label: l10n.sendRequest,
              onPressed: submit.isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

extension on BusinessType {
  String label(AppLocalizations l10n) => switch (this) {
    BusinessType.proprietorship => l10n.businessProprietorship,
    BusinessType.partnership => l10n.businessPartnership,
    BusinessType.llp => l10n.businessLlp,
    BusinessType.privateLimited => l10n.businessPrivateLimited,
    BusinessType.publicLimited => l10n.businessPublicLimited,
    BusinessType.other => l10n.businessOther,
  };
}
