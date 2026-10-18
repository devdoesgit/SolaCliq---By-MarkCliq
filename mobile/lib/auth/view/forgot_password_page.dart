import 'dart:async';

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
import 'package:solacliq/l10n/l10n.dart';

class ForgotPasswordPage extends StatelessWidget {
  const new({this.initialEmail, super.key});

  final String? initialEmail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmitCubit(),
      child: ForgotPasswordView(initialEmail: initialEmail),
    );
  }
}

class ForgotPasswordView extends StatefulWidget {
  const new({this.initialEmail, super.key});

  final String? initialEmail;

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
    return BlocConsumer<SubmitCubit, SubmitState>(
      listenWhen: (a, b) => b.status == SubmitStatus.success,
      listener: (context, _) =>
          context.pushReplacement(AppRoutes.resetPassword(_email.text.trim())),
      builder: (context, state) => AuthLayout(
        title: l10n.forgotTitle,
        intro: l10n.forgotIntro,
        onBack: context.canPop() ? context.pop : null,
        notice: FailureNotice(state: state),
        primaryAction: SolaButton(
          key: const Key('forgot_submit'),
          label: l10n.sendCode,
          variant: SolaButtonVariant.primary,
          expand: true,
          onPressed: state.isSubmitting ? null : _submit,
        ),
        children: [
          SolaTextField(
            key: const Key('forgot_email'),
            label: l10n.fieldEmail,
            controller: _email,
            error: _emailError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => context.read<SubmitCubit>().reset(),
            onSubmitted: (_) => unawaited(_submit()),
          ),
        ],
      ),
    );
  }
}
