import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/access/data/access_repository.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/auth/widgets/failure_notice.dart';
import 'package:solacliq/l10n/l10n.dart';

/// A solar company asks for SolaCliq: who they are and how to reach them.
/// MarkCliq calls and onboards them; their admin works on the website.
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
  final _company = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _email = TextEditingController();
  final _errors = <String, String?>{};

  @override
  void dispose() {
    for (final c in [_company, _owner, _phone, _city, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  void _edited(String _) => context.read<SubmitCubit>().reset();

  Future<void> _submit() async {
    context
      ..fillBlank(_company, 'Sample Solar (illustrative)')
      ..fillBlank(_owner, 'Ravi Example')
      ..fillBlank(_phone, '98765 43210')
      ..fillBlank(_city, 'Jaipur')
      ..fillBlank(_email, 'ravi@example.com');
    final l10n = context.l10n;
    setState(() {
      _errors
        ..['company'] = AuthValidators.required(
          _company.text,
          l10n.fieldCompanyName,
          l10n,
        )
        ..['owner'] = AuthValidators.required(_owner.text, l10n.fieldName, l10n)
        ..['phone'] = AuthValidators.mobile(_phone.text, l10n)
        ..['city'] = AuthValidators.required(_city.text, l10n.fieldCity, l10n)
        ..['email'] = AuthValidators.email(_email.text.trim(), l10n);
    });
    if (_errors.values.any((e) => e != null)) return;
    final access = context.read<AccessRepository>();
    await context.read<SubmitCubit>().submit(
      () => access.requestAccess(
        companyName: _company.text.trim(),
        ownerName: _owner.text.trim(),
        phone: AuthValidators.digits(_phone.text),
        city: _city.text.trim(),
        email: _email.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SubmitCubit, SubmitState>(
      listenWhen: (a, b) => b.status == SubmitStatus.success,
      listener: (context, _) => context.pushReplacement(
        AppRoutes.requestSentTo(
          company: _company.text.trim(),
          email: _email.text.trim(),
        ),
      ),
      builder: (context, state) => SolaScreen(
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
            if (state.status == SubmitStatus.failure) ...[
              FailureNotice(state: state),
              const SizedBox(height: SolaSpace.space14),
            ],
            SolaGroup(
              children: [
                SolaFieldRow(
                  key: const ValueKey('access_company'),
                  label: l10n.fieldCompanyName,
                  controller: _company,
                  error: _errors['company'],
                  placeholder: l10n.companyPlaceholder,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.organizationName],
                  onChanged: _edited,
                ),
                SolaFieldRow(
                  key: const ValueKey('access_owner'),
                  label: l10n.fieldName,
                  controller: _owner,
                  error: _errors['owner'],
                  placeholder: l10n.fullNamePlaceholder,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  onChanged: _edited,
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
                  onChanged: _edited,
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
                  onChanged: _edited,
                ),
                SolaFieldRow(
                  key: const ValueKey('access_email'),
                  label: l10n.fieldWorkEmail,
                  controller: _email,
                  error: _errors['email'],
                  placeholder: l10n.workEmailPlaceholder,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => unawaited(_submit()),
                  onChanged: _edited,
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
              onPressed: state.isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
