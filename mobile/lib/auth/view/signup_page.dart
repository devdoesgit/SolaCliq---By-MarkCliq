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
  final _password = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _edited(String _) => context.read<SubmitCubit>().reset();

  Future<void> _submit() async {
    final l10n = context.l10n;
    final email = _email.text.trim();
    setState(() {
      _nameError = AuthValidators.name(_name.text, l10n);
      _emailError = AuthValidators.email(email, l10n);
      _passwordError = AuthValidators.newPassword(_password.text, l10n);
    });
    if (_nameError != null || _emailError != null || _passwordError != null) {
      return;
    }
    TextInput.finishAutofillContext();
    final auth = context.read<AuthRepository>();
    await context.read<SubmitCubit>().submit(
      () => auth.signUp(
        name: _name.text.trim(),
        email: email,
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SubmitCubit, SubmitState>(
      listenWhen: (a, b) => b.status == SubmitStatus.success,
      listener: (context, _) =>
          context.pushReplacement(AppRoutes.verifyEmail(_email.text.trim())),
      builder: (context, state) => AutofillGroup(
        child: AuthLayout(
          title: l10n.createAccount,
          intro: l10n.signupIntro,
          onBack: context.canPop() ? context.pop : null,
          notice: FailureNotice(state: state),
          primaryAction: SolaButton(
            key: const Key('signup_submit'),
            label: l10n.createAccount,
            variant: SolaButtonVariant.primary,
            expand: true,
            onPressed: state.isSubmitting ? null : _submit,
          ),
          children: [
            SolaTextField(
              key: const Key('signup_name'),
              label: l10n.fieldName,
              controller: _name,
              error: _nameError,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onChanged: _edited,
            ),
            SolaTextField(
              key: const Key('signup_email'),
              label: l10n.fieldEmail,
              controller: _email,
              error: _emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onChanged: _edited,
            ),
            PasswordField(
              key: const Key('signup_password'),
              label: l10n.fieldPassword,
              help: l10n.passwordHelp,
              controller: _password,
              error: _passwordError,
              isNew: true,
              onChanged: _edited,
              onSubmitted: (_) => unawaited(_submit()),
            ),
          ],
        ),
      ),
    );
  }
}
