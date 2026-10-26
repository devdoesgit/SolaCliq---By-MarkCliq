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

/// Why the person arrived here, shown as a success message.
enum LoginNotice { emailVerified, passwordChanged, passwordCreated }

class LoginPage extends StatelessWidget {
  const new({this.initialEmail, this.notice, super.key});

  final String? initialEmail;
  final LoginNotice? notice;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmitCubit(),
      child: LoginView(initialEmail: initialEmail, notice: notice),
    );
  }
}

class LoginView extends StatefulWidget {
  const new({this.initialEmail, this.notice, super.key});

  final String? initialEmail;
  final LoginNotice? notice;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _edited(String _) {
    context.read<SubmitCubit>().reset();
    if (_emailError != null || _passwordError != null) {
      setState(() => _emailError = _passwordError = null);
    }
  }

  Future<void> _submit() async {
    context
      ..fillBlank(_email, 'asha@example.com')
      ..fillBlank(_password, 'solarpanel26');
    final l10n = context.l10n;
    final email = _email.text.trim();
    setState(() {
      _emailError = AuthValidators.email(email, l10n);
      _passwordError = AuthValidators.existingPassword(_password.text, l10n);
    });
    if (_emailError != null || _passwordError != null) return;
    TextInput.finishAutofillContext();
    final auth = context.read<AuthRepository>();
    // Success needs no navigation: the router sends signed-in people home.
    await context.read<SubmitCubit>().submit(
      () => auth.logIn(email: email, password: _password.text),
    );
  }

  void _verifyInstead() {
    final email = _email.text.trim();
    unawaited(
      context
          .read<AuthRepository>()
          .resendVerification(email: email)
          .catchError((Object _) {}),
    );
    unawaited(context.push(AppRoutes.verifyEmail(email)));
  }

  void _setUpAccount() => unawaited(
    context.push(AppRoutes.forgotPassword(_email.text.trim(), setup: true)),
  );

  Widget? _failureAction(AuthFailureCode? failure) => switch (failure) {
    AuthFailureCode.emailUnverified => SolaButton(
      key: const Key('login_verify_now'),
      label: context.l10n.verifyNow,
      variant: SolaButtonVariant.white,
      compact: true,
      expand: false,
      onPressed: _verifyInstead,
    ),
    AuthFailureCode.passwordNotSet => SolaButton(
      key: const Key('login_set_up_now'),
      label: context.l10n.setUpAccount,
      variant: SolaButtonVariant.white,
      compact: true,
      expand: false,
      onPressed: _setUpAccount,
    ),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SubmitCubit>().state;
    final notice = widget.notice;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AutofillGroup(
        child: SolaScreen(
          navBar: const SolaNavBar(
            leading: BackTo(fallback: AppRoutes.welcome),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: SolaSpace.space14),
              SolaTitleBlock(
                title: l10n.loginTitle,
                subtitle: l10n.loginBody,
                style: SolaTextStyle.largeTitle,
              ),
              const SizedBox(height: SolaSpace.space26),
              if (state.status == SubmitStatus.failure) ...[
                FailureNotice(
                  state: state,
                  action: _failureAction(state.failure),
                ),
                const SizedBox(height: SolaSpace.space14),
              ] else if (notice != null) ...[
                SolaNotice(
                  title: switch (notice) {
                    LoginNotice.emailVerified => l10n.emailVerified,
                    LoginNotice.passwordChanged => l10n.passwordChanged,
                    LoginNotice.passwordCreated => l10n.passwordCreated,
                  },
                  tone: SolaTone.success,
                ),
                const SizedBox(height: SolaSpace.space14),
              ],
              SolaGroup(
                children: [
                  SolaFieldRow(
                    key: const ValueKey('login_email'),
                    label: l10n.fieldEmail,
                    placeholder: l10n.emailPlaceholder,
                    controller: _email,
                    error: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    onChanged: _edited,
                  ),
                  PasswordField(
                    key: const ValueKey('login_password'),
                    label: l10n.fieldPassword,
                    controller: _password,
                    error: _passwordError,
                    onChanged: _edited,
                    onSubmitted: (_) => unawaited(_submit()),
                  ),
                ],
              ),
              const SizedBox(height: SolaSpace.space14),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SolaTextLink(
                  l10n.forgotPassword,
                  key: const Key('login_forgot_password'),
                  style: SolaTextStyle.body,
                  onPressed: () => unawaited(
                    context.push(AppRoutes.forgotPassword(_email.text.trim())),
                  ),
                ),
              ),
            ],
          ),
          bottom: SolaBottomBar(
            children: [
              SolaButton(
                key: const Key('login_submit'),
                label: l10n.logIn,
                onPressed: state.isSubmitting ? null : _submit,
              ),
              SolaLinkText(
                key: const Key('login_create_account'),
                before: l10n.newToSolaCliqBefore,
                link: l10n.createAccountLink,
                onTap: () => unawaited(context.push(AppRoutes.signup)),
              ),
              const _SecuredBy(),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Secured by MarkCliq" with a padlock, under the log in button.
class _SecuredBy extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: SolaSpace.space6,
      children: [
        const SolaIcon(SolaIcons.lock, size: 12, color: SolaColors.muted),
        SolaText(
          context.l10n.securedBy,
          style: SolaTextStyle.eyebrowSm,
          color: SolaColors.muted,
        ),
      ],
    );
  }
}
