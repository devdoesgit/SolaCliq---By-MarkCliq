import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/auth/widgets/failure_notice.dart';
import 'package:solacliq/auth/widgets/password_field.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Creates a free personal account, then verifies the email.
class SignupPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmitCubit(),
      child: const SignupView(),
    );
  }
}

class SignupView extends StatefulWidget {
  const new({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _mobileError;
  String? _passwordError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  void _edited(String _) => context.read<SubmitCubit>().reset();

  Future<void> _submit() async {
    context
      ..fillBlank(_name, 'Asha Example')
      ..fillBlank(_email, 'asha@example.com')
      ..fillBlank(_password, 'solarpanel26');
    final l10n = context.l10n;
    final email = _email.text.trim();
    setState(() {
      _nameError = AuthValidators.required(
        _name.text,
        l10n.fieldFullName,
        l10n,
      );
      _emailError = AuthValidators.email(email, l10n);
      _mobileError = AuthValidators.optionalMobile(_mobile.text, l10n);
      _passwordError = AuthValidators.newPassword(_password.text, l10n);
    });
    if ([
      _nameError,
      _emailError,
      _mobileError,
      _passwordError,
    ].any((e) => e != null)) {
      return;
    }
    TextInput.finishAutofillContext();
    final auth = context.read<AuthRepository>();
    final pending = context.read<PendingLogin>();
    final mobile = AuthValidators.digits(_mobile.text);
    await context.read<SubmitCubit>().submit(() async {
      await auth.signUp(
        name: _name.text.trim(),
        email: email,
        password: _password.text,
        phone: mobile.isEmpty ? null : mobile,
      );
      // Verifying logs straight in with this, without asking again.
      pending.hold(email: email, password: _password.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SubmitCubit, SubmitState>(
      listenWhen: (a, b) => b.status == SubmitStatus.success,
      listener: (context, _) =>
          unawaited(context.push(AppRoutes.verifyEmail(_email.text.trim()))),
      builder: (context, state) => AutofillGroup(
        child: SolaScreen(
          navBar: SolaNavBar(
            leading: const BackTo(fallback: AppRoutes.login),
            title: l10n.createAccount,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: SolaSpace.space14),
              SolaTitleBlock(
                title: l10n.signupTitle,
                subtitle: l10n.signupBody,
                style: SolaTextStyle.largeTitle,
              ),
              const SizedBox(height: SolaSpace.space24),
              if (state.status == SubmitStatus.failure) ...[
                FailureNotice(state: state),
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
                    onChanged: _edited,
                  ),
                  SolaFieldRow(
                    key: const ValueKey('signup_email'),
                    label: l10n.fieldEmail,
                    placeholder: l10n.emailPlaceholder,
                    controller: _email,
                    error: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    onChanged: _edited,
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
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                      LengthLimitingTextInputFormatter(11),
                    ],
                    onChanged: _edited,
                  ),
                  PasswordField(
                    key: const ValueKey('signup_password'),
                    label: l10n.fieldPassword,
                    controller: _password,
                    error: _passwordError,
                    isNew: true,
                    onChanged: _edited,
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
            ],
          ),
          bottom: SolaBottomBar(
            children: [
              SolaButton(
                key: const Key('signup_submit'),
                label: l10n.createAccount,
                onPressed: state.isSubmitting ? null : _submit,
              ),
              SolaLinkText(
                key: const Key('signup_log_in'),
                before: l10n.alreadyOnBefore,
                link: l10n.logIn,
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
