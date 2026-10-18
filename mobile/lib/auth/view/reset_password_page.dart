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

class ResetPasswordPage extends StatelessWidget {
  const new({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmitCubit(),
      child: ResetPasswordView(email: email),
    );
  }
}

class ResetPasswordView extends StatefulWidget {
  const new({required this.email, super.key});

  final String email;

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  String? _codeError;
  String? _passwordError;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _edited(String _) => context.read<SubmitCubit>().reset();

  Future<void> _submit() async {
    final l10n = context.l10n;
    setState(() {
      _codeError = AuthValidators.code(_code.text, l10n);
      _passwordError = AuthValidators.newPassword(_password.text, l10n);
    });
    if (_codeError != null || _passwordError != null) return;
    TextInput.finishAutofillContext();
    final auth = context.read<AuthRepository>();
    await context.read<SubmitCubit>().submit(
      () => auth.resetPassword(
        email: widget.email,
        code: _code.text.trim(),
        newPassword: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SubmitCubit, SubmitState>(
      listenWhen: (a, b) => b.status == SubmitStatus.success,
      listener: (context, _) =>
          context.go(AppRoutes.loginAfterReset(widget.email)),
      builder: (context, state) => AutofillGroup(
        child: AuthLayout(
          title: l10n.resetTitle,
          intro: l10n.resetIntro(widget.email),
          onBack: context.canPop() ? context.pop : null,
          notice: FailureNotice(state: state),
          primaryAction: SolaButton(
            key: const Key('reset_submit'),
            label: l10n.resetButton,
            variant: SolaButtonVariant.primary,
            expand: true,
            onPressed: state.isSubmitting ? null : _submit,
          ),
          children: [
            SolaTextField(
              key: const Key('reset_code'),
              label: l10n.fieldCode,
              controller: _code,
              error: _codeError,
              numeric: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: _edited,
            ),
            PasswordField(
              key: const Key('reset_password'),
              label: l10n.fieldNewPassword,
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
