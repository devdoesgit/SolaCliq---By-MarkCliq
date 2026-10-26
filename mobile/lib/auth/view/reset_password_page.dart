import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// Sets a password with the emailed code, then logs straight in. With
/// [setup], worded as creating the first password on an account someone
/// else created.
class ResetPasswordPage extends StatelessWidget {
  const new({required this.email, this.setup = false, super.key});

  final String email;
  final bool setup;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmitCubit(),
      child: ResetPasswordView(email: email, setup: setup),
    );
  }
}

class ResetPasswordView extends StatefulWidget {
  const new({required this.email, this.setup = false, super.key});

  final String email;
  final bool setup;

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _codeError;
  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    // The checklist follows what is typed.
    _password.addListener(_rebuild);
    _confirm.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _edited(String _) => context.read<SubmitCubit>().reset();

  Future<void> _submit() async {
    context
      ..fillBlank(_code, '111222')
      ..fillBlank(_password, 'solarpanel26')
      ..fillBlank(_confirm, 'solarpanel26');
    final l10n = context.l10n;
    setState(() {
      _codeError = AuthValidators.code(_code.text, l10n);
      _passwordError = AuthValidators.newPassword(_password.text, l10n);
      _confirmError = AuthValidators.confirmPassword(
        _confirm.text,
        _password.text,
        l10n,
      );
    });
    if (_codeError != null || _passwordError != null || _confirmError != null) {
      return;
    }
    TextInput.finishAutofillContext();
    final auth = context.read<AuthRepository>();
    final email = widget.email;
    final password = _password.text;
    await context.read<SubmitCubit>().submit(() async {
      await auth.resetPassword(
        email: email,
        code: _code.text.trim(),
        newPassword: password,
      );
      // The router sends the signed-in person home.
      await auth.logIn(email: email, password: password);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SubmitCubit>().state;
    final rules = AuthValidators.passwordRules(_password.text);
    final matches =
        _password.text.isNotEmpty && _password.text == _confirm.text;
    return AutofillGroup(
      child: SolaScreen(
        // First-time set up is for customers an agent registered.
        background: widget.setup ? SolaBackground.sky : SolaBackground.cream,
        navBar: const SolaNavBar(leading: BackTo(fallback: AppRoutes.login)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: SolaSpace.space14),
            SolaTitleBlock(
              title: widget.setup
                  ? l10n.createPasswordTitle
                  : l10n.newPasswordTitle,
              subtitle: l10n.logInWith2(widget.email),
            ),
            const SizedBox(height: SolaSpace.space24),
            if (state.status == SubmitStatus.failure) ...[
              FailureNotice(state: state),
              const SizedBox(height: SolaSpace.space14),
            ],
            // The designs reach this screen from an emailed link; until
            // that link exists the emailed code proves the email is theirs.
            SolaSectionLabel(l10n.codeFromEmail2),
            const SizedBox(height: SolaSpace.space8),
            SolaCodeInput(
              key: const ValueKey('reset_code'),
              label: l10n.codeFromEmail2,
              controller: _code,
              error: _codeError != null,
              onCompleted: (_) => context.read<SubmitCubit>().reset(),
            ),
            if (_codeError case final error?) ...[
              const SizedBox(height: SolaSpace.space8),
              SolaText(
                error,
                style: SolaTextStyle.meta,
                color: SolaColors.danger,
              ),
            ],
            const SizedBox(height: SolaSpace.space16),
            SolaGroup(
              children: [
                PasswordField(
                  key: const ValueKey('reset_password'),
                  label: l10n.fieldNewPassword,
                  controller: _password,
                  error: _passwordError,
                  isNew: true,
                  textInputAction: TextInputAction.next,
                  onChanged: _edited,
                ),
                PasswordField(
                  key: const ValueKey('reset_confirm'),
                  label: l10n.fieldConfirmPassword,
                  controller: _confirm,
                  error: _confirmError,
                  isNew: true,
                  showToggle: false,
                  onChanged: _edited,
                  onSubmitted: (_) => unawaited(_submit()),
                ),
              ],
            ),
            const SizedBox(height: SolaSpace.space16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SolaSpace.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SolaSpace.space10,
                children: [
                  _Rule(text: l10n.ruleLength, met: rules.length),
                  _Rule(text: l10n.ruleNumber, met: rules.number),
                  _Rule(text: l10n.ruleMatch2, met: matches),
                ],
              ),
            ),
          ],
        ),
        bottom: SolaBottomBar(
          children: [
            SolaButton(
              key: const Key('reset_submit'),
              label: l10n.saveAndContinue,
              onPressed: state.isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// One password rule: a dark tick circle once it is met.
class _Rule extends StatelessWidget {
  const new({required this.text, required this.met});

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: met,
      label: text,
      excludeSemantics: true,
      child: Row(
        spacing: SolaSpace.space8,
        children: [
          AnimatedContainer(
            duration: SolaMotion.durationFast,
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: met ? SolaColors.brown : SolaColors.surface,
              shape: BoxShape.circle,
              border: met
                  ? null
                  : Border.all(color: SolaColors.dashed, width: 1.5),
            ),
            child: met
                ? const Center(
                    child: SolaIcon(
                      SolaIcons.check,
                      size: 12,
                      color: SolaColors.cream,
                    ),
                  )
                : null,
          ),
          Flexible(
            child: SolaText(
              text,
              style: SolaTextStyle.small,
              color: met ? SolaColors.ink : SolaColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
