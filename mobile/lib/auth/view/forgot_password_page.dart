import 'dart:async';

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
import 'package:solacliq/l10n/l10n.dart';

/// Requests an emailed code to reset a password, or, with [setup], to
/// create the first password on an account an agent or admin created.
class ForgotPasswordPage extends StatelessWidget {
  const new({this.initialEmail, this.setup = false, super.key});

  final String? initialEmail;
  final bool setup;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmitCubit(),
      child: ForgotPasswordView(initialEmail: initialEmail, setup: setup),
    );
  }
}

class ForgotPasswordView extends StatefulWidget {
  const new({this.initialEmail, this.setup = false, super.key});

  final String? initialEmail;
  final bool setup;

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final _email = TextEditingController(text: widget.initialEmail);
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.fillBlank(_email, 'asha@example.com');
    final email = _email.text.trim();
    final error = AuthValidators.email(email, context.l10n);
    setState(() => _emailError = error);
    if (error != null) return;
    final auth = context.read<AuthRepository>();
    await context.read<SubmitCubit>().submit(
      () => auth.requestPasswordReset(email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final setup = widget.setup;
    return BlocConsumer<SubmitCubit, SubmitState>(
      listenWhen: (a, b) => b.status == SubmitStatus.success,
      listener: (context, _) => context.pushReplacement(
        AppRoutes.resetPassword(_email.text.trim(), setup: setup),
      ),
      builder: (context, state) => SolaScreen(
        navBar: const SolaNavBar(leading: BackTo(fallback: AppRoutes.login)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: SolaSpace.space14),
            SolaTitleBlock(
              title: setup ? l10n.setupTitle2 : l10n.forgotTitle2,
              subtitle: setup ? l10n.setupBody2 : l10n.forgotBody,
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
                  key: const ValueKey('forgot_email'),
                  label: l10n.fieldEmail,
                  placeholder: l10n.emailPlaceholder,
                  controller: _email,
                  error: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onChanged: (_) => context.read<SubmitCubit>().reset(),
                  onSubmitted: (_) => unawaited(_submit()),
                ),
              ],
            ),
          ],
        ),
        bottom: SolaBottomBar(
          children: [
            SolaButton(
              key: const Key('forgot_submit'),
              label: l10n.sendCode,
              onPressed: state.isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
