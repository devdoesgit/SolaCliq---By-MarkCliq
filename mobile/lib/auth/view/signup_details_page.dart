import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/app/widgets/mobile_formatter.dart';
import 'package:solacliq/app/widgets/reveal_error.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/auth/widgets/failure_notice.dart';
import 'package:solacliq/auth/widgets/password_field.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/legal/view/terms_agreement.dart';

/// Sign-up step 3: the details, after the code proved the inbox. Creates
/// the account and signs in.
class SignupDetailsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmitCubit(),
      child: const SignupDetailsView(),
    );
  }
}

class SignupDetailsView extends StatefulWidget {
  const new({super.key});

  @override
  State<SignupDetailsView> createState() => _SignupDetailsViewState();
}

class _SignupDetailsViewState extends State<SignupDetailsView> {
  final _name = TextEditingController();
  // Read once: cleared when done, while this page is still leaving.
  late final String _email = context.read<PendingSignup>().email ?? '';
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  String? _nameError;
  String? _mobileError;
  String? _passwordError;
  bool _agreed = false;
  String? _termsError;

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  // An edit clears that field's error, and the banner.
  void _edited(String? error, VoidCallback clear) {
    context.read<SubmitCubit>().reset();
    if (error != null) setState(clear);
  }

  Future<void> _submit() async {
    context
      ..fillBlank(_name, 'Asha Example')
      ..fillBlank(_password, 'solarpanel26');
    // Quick forms (development only) fills every choice; never in a release.
    if (context.quickForms) _agreed = true;
    final l10n = context.l10n;
    setState(() {
      _nameError = AuthValidators.required(_name.text, l10n.errorNameRequired);
      _mobileError = AuthValidators.optionalMobile(_mobile.text, l10n);
      _passwordError = AuthValidators.newPassword(_password.text, l10n);
      _termsError = _agreed ? null : l10n.errorTerms;
    });
    if ([
      _nameError,
      _mobileError,
      _passwordError,
      _termsError,
    ].any((e) => e != null)) {
      revealFirstError(context, [
        (_nameError != null, const ValueKey('signup_name')),
        (_mobileError != null, const ValueKey('signup_mobile')),
        (_passwordError != null, const ValueKey('signup_password')),
        (_termsError != null, const ValueKey('signup_terms')),
      ]);
      return;
    }
    TextInput.finishAutofillContext();
    final auth = context.read<AuthRepository>();
    final pending = context.read<PendingSignup>();
    final token = pending.token;
    if (token == null) return context.go(AppRoutes.signup);
    final mobile = AuthValidators.digits(_mobile.text);
    await context.read<SubmitCubit>().submit(() async {
      // The router sends the signed-in person home.
      await auth.completeSignUp(
        token: token,
        name: _name.text.trim(),
        password: _password.text,
        phone: mobile.isEmpty ? null : mobile,
      );
      pending.clear();
    });
  }

  void _startAgain() {
    context.read<PendingSignup>().clear();
    context.go(AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<SubmitCubit, SubmitState>(
      builder: (context, state) => AutofillGroup(
        child: SolaScreen(
          navBar: SolaNavBar(
            leading: const BackTo(fallback: AppRoutes.signup),
            title: l10n.createAccount,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: SolaSpace.space14),
              SolaTitleBlock(
                title: l10n.signupDetailsTitle,
                subtitle: l10n.signupDetailsBody(_email),
                style: SolaTextStyle.largeTitle,
              ),
              const SizedBox(height: SolaSpace.space24),
              if (state.status == SubmitStatus.failure) ...[
                FailureNotice(
                  state: state,
                  action: state.failure == AuthFailureCode.signupExpired
                      ? SolaButton(
                          key: const Key('signup_start_again'),
                          label: l10n.startAgain,
                          variant: SolaButtonVariant.white,
                          compact: true,
                          expand: false,
                          onPressed: _startAgain,
                        )
                      : null,
                ),
                const SizedBox(height: SolaSpace.space14),
              ],
              SolaGroup(
                children: [
                  SolaFieldRow(
                    key: const ValueKey('signup_name'),
                    label: l10n.fieldFullName,
                    placeholder: l10n.fullNamePlaceholder,
                    controller: _name,
                    error: _nameError,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    onChanged: (_) =>
                        _edited(_nameError, () => _nameError = null),
                  ),
                  SolaFieldRow(
                    key: const ValueKey('signup_mobile'),
                    label: l10n.fieldMobile2,
                    prefixText: '+91 ',
                    placeholder: l10n.phonePlaceholder,
                    controller: _mobile,
                    error: _mobileError,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.telephoneNumberNational,
                    ],
                    inputFormatters: const [MobileNumberFormatter()],
                    onChanged: (_) =>
                        _edited(_mobileError, () => _mobileError = null),
                  ),
                  PasswordField(
                    key: const ValueKey('signup_password'),
                    label: l10n.fieldPassword,
                    controller: _password,
                    error: _passwordError,
                    isNew: true,
                    onChanged: (_) =>
                        _edited(_passwordError, () => _passwordError = null),
                    onSubmitted: (_) => unawaited(_submit()),
                  ),
                ],
              ),
              const SizedBox(height: SolaSpace.space10),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SolaSpace.space4,
                ),
                child: SolaText(
                  l10n.signupPasswordRule,
                  style: SolaTextStyle.meta,
                  color: SolaColors.muted,
                ),
              ),
              const SizedBox(height: SolaSpace.space24),
              TermsAgreement(
                key: const ValueKey('signup_terms'),
                value: _agreed,
                error: _termsError,
                onChanged: (v) => setState(() {
                  _agreed = v;
                  _termsError = null;
                }),
              ),
            ],
          ),
          bottom: SolaBottomBar(
            children: [
              SolaButton(
                key: const Key('signup_submit'),
                label: l10n.createAccount,
                onPressed: state.isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
