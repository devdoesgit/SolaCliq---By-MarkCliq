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

/// Separate from the verify request, so sending a new code doesn't block
/// or reset the verify button.
class ResendCubit extends SubmitCubit;

/// Enters the emailed code. Just after sign-up it logs straight in; reached
/// another way, it returns to log in.
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

class VerifyEmailView extends StatefulWidget {
  const new({required this.email, super.key});

  final String email;

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final _code = TextEditingController();
  String? _codeError;
  Timer? _timer;
  int _wait = _resendDelay;

  /// Seconds before another code can be sent.
  static const _resendDelay = 30;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _wait = _resendDelay);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_wait <= 1) timer.cancel();
      if (mounted) setState(() => _wait--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.fillBlank(_code, '482913');
    final error = AuthValidators.code(_code.text, context.l10n);
    setState(() => _codeError = error);
    if (error != null) return;
    final auth = context.read<AuthRepository>();
    final pending = context.read<PendingLogin>();
    final email = widget.email;
    final router = GoRouter.of(context);
    await context.read<SubmitCubit>().submit(() async {
      await auth.verifyEmail(email: email, code: _code.text.trim());
      final password = pending.take(email);
      if (password == null) {
        router.go(AppRoutes.loginAfterVerify(email));
      } else {
        // The router sends the signed-in person home.
        await auth.logIn(email: email, password: password);
      }
    });
  }

  Future<void> _resend() async {
    final auth = context.read<AuthRepository>();
    await context.read<ResendCubit>().submit(
      () => auth.resendVerification(email: widget.email),
    );
    if (mounted) _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SubmitCubit>().state;
    final resend = context.watch<ResendCubit>().state;
    final seconds = _wait.toString().padLeft(2, '0');
    return SolaScreen(
      navBar: const SolaNavBar(leading: BackTo(fallback: AppRoutes.login)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: SolaSpace.space14),
          SolaTitleBlock(
            title: l10n.verifyTitle2,
            subtitle: l10n.verifyBody(widget.email),
            style: SolaTextStyle.largeTitle,
          ),
          const SizedBox(height: SolaSpace.space28),
          if (state.status == SubmitStatus.failure) ...[
            FailureNotice(state: state),
            const SizedBox(height: SolaSpace.space14),
          ] else if (resend.status == SubmitStatus.failure) ...[
            FailureNotice(state: resend),
            const SizedBox(height: SolaSpace.space14),
          ] else if (resend.status == SubmitStatus.success) ...[
            SolaNotice(title: l10n.codeSent, tone: SolaTone.success),
            const SizedBox(height: SolaSpace.space14),
          ],
          SolaCodeInput(
            key: const ValueKey('verify_code'),
            label: l10n.codeLabel,
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
          const SizedBox(height: SolaSpace.space18),
          // Wraps under large text sizes instead of overflowing.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_wait > 0)
                SolaText(l10n.resendIn2('0:$seconds'), color: SolaColors.muted)
              else
                SolaTextLink(
                  l10n.resendCode,
                  key: const Key('verify_resend'),
                  style: SolaTextStyle.body,
                  onPressed: resend.isSubmitting
                      ? null
                      : () => unawaited(_resend()),
                ),
              SolaTextLink(
                l10n.changeEmail,
                key: const Key('verify_change_email'),
                style: SolaTextStyle.body,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.signup),
              ),
            ],
          ),
        ],
      ),
      bottom: SolaBottomBar(
        children: [
          SolaButton(
            key: const Key('verify_submit'),
            label: l10n.verify,
            onPressed: state.isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
