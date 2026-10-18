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
import 'package:solacliq/l10n/l10n.dart';

class VerifyEmailPage extends StatelessWidget {
  const new({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SubmitCubit()),
        BlocProvider(create: (_) => ResendCubit()),
      ],
      child: VerifyEmailView(email: email),
    );
  }
}

/// The "Send a new code" request, separate from verifying.
class ResendCubit extends SubmitCubit;

class VerifyEmailView extends StatefulWidget {
  const new({required this.email, super.key});

  final String email;

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final _code = TextEditingController();
  String? _codeError;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = AuthValidators.code(_code.text, context.l10n);
    setState(() => _codeError = error);
    if (error != null) return;
    final auth = context.read<AuthRepository>();
    await context.read<SubmitCubit>().submit(
      () => auth.verifyEmail(email: widget.email, code: _code.text.trim()),
    );
  }

  Future<void> _resend() {
    final auth = context.read<AuthRepository>();
    return context.read<ResendCubit>().submit(
      () => auth.resendVerification(email: widget.email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resend = context.watch<ResendCubit>().state;
    return BlocConsumer<SubmitCubit, SubmitState>(
      listenWhen: (a, b) => b.status == SubmitStatus.success,
      listener: (context, _) =>
          context.go(AppRoutes.loginAfterVerify(widget.email)),
      builder: (context, state) => AuthLayout(
        title: l10n.verifyTitle,
        intro: l10n.verifyIntro(widget.email),
        onBack: context.canPop() ? context.pop : null,
        notice: state.status == SubmitStatus.failure
            ? FailureNotice(state: state)
            : resend.status == SubmitStatus.failure
            ? FailureNotice(state: resend)
            : resend.status == SubmitStatus.success
            ? SolaNotice(title: l10n.codeSent, tone: SolaTone.success)
            : null,
        primaryAction: SolaButton(
          key: const Key('verify_submit'),
          label: l10n.verifyButton,
          variant: SolaButtonVariant.primary,
          expand: true,
          onPressed: state.isSubmitting ? null : _submit,
        ),
        secondaryActions: [
          SolaButton(
            key: const Key('verify_resend'),
            label: l10n.resendCode,
            variant: SolaButtonVariant.ghost,
            onPressed: resend.isSubmitting ? null : () => unawaited(_resend()),
          ),
        ],
        children: [
          SolaTextField(
            key: const Key('verify_code'),
            label: l10n.fieldCode,
            controller: _code,
            error: _codeError,
            numeric: true,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => context.read<SubmitCubit>().reset(),
            onSubmitted: (_) => unawaited(_submit()),
          ),
        ],
      ),
    );
  }
}
