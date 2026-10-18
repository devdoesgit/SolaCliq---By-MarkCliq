import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/auth/widgets/auth_layout.dart';
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
      onPressed: _verifyInstead,
    ),
    AuthFailureCode.passwordNotSet => SolaButton(
      key: const Key('login_set_up_now'),
      label: context.l10n.setUpAccount,
      onPressed: _setUpAccount,
    ),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SubmitCubit>().state;
    final notice = widget.notice;
    return AutofillGroup(
      child: AuthLayout(
        title: l10n.logIn,
        onBack: context.canPop() ? context.pop : null,
        notice: state.status == SubmitStatus.failure
            ? FailureNotice(state: state, action: _failureAction(state.failure))
            : notice == null
            ? null
            : SolaNotice(
                title: switch (notice) {
                  LoginNotice.emailVerified => l10n.emailVerified,
                  LoginNotice.passwordChanged => l10n.passwordChanged,
                  LoginNotice.passwordCreated => l10n.passwordCreated,
                },
                tone: SolaTone.success,
              ),
        primaryAction: SolaButton(
          key: const Key('login_submit'),
          label: l10n.logIn,
          variant: SolaButtonVariant.primary,
          expand: true,
          onPressed: state.isSubmitting ? null : _submit,
        ),
        secondaryActions: [
          SolaButton(
            key: const Key('login_forgot_password'),
            label: l10n.forgotPassword,
            variant: SolaButtonVariant.ghost,
            onPressed: () =>
                context.push(AppRoutes.forgotPassword(_email.text.trim())),
          ),
          SolaButton(
            key: const Key('login_first_time'),
            label: l10n.firstTimeHere,
            variant: SolaButtonVariant.ghost,
            onPressed: _setUpAccount,
          ),
        ],
        children: [
          SolaTextField(
            key: const Key('login_email'),
            label: l10n.fieldEmail,
            controller: _email,
            error: _emailError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            onChanged: _edited,
          ),
          PasswordField(
            key: const Key('login_password'),
            label: l10n.fieldPassword,
            controller: _password,
            error: _passwordError,
            onChanged: _edited,
            onSubmitted: (_) => unawaited(_submit()),
          ),
        ],
      ),
    );
  }
}
