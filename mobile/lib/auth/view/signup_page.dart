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

/*
  Sign-up step 1: the email alone
  ----------------------------------------------------------------------
  - email, then code, then details (QA-27): nothing about a person is
    sent, let alone saved, before their inbox is proven
*/
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
  final _email = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _edited(String _) {
    context.read<SubmitCubit>().reset();
    if (_emailError != null) setState(() => _emailError = null);
  }

  Future<void> _submit() async {
    context.fillBlank(_email, 'asha@example.com');
    final email = _email.text.trim();
    final error = AuthValidators.email(email, context.l10n);
    setState(() => _emailError = error);
    if (error != null) return;
    final auth = context.read<AuthRepository>();
    await context.read<SubmitCubit>().submit(
      () => auth.startSignUp(email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SubmitCubit, SubmitState>(
      listenWhen: (a, b) => b.status == SubmitStatus.success,
      listener: (context, _) =>
          unawaited(context.push(AppRoutes.verifyEmail(_email.text.trim()))),
      builder: (context, state) => SolaScreen(
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
                  key: const ValueKey('signup_email'),
                  label: l10n.fieldEmail,
                  placeholder: l10n.emailPlaceholder,
                  controller: _email,
                  error: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onChanged: _edited,
                  onSubmitted: (_) => unawaited(_submit()),
                ),
              ],
            ),
          ],
        ),
        bottom: SolaBottomBar(
          children: [
            SolaButton(
              key: const Key('signup_submit'),
              label: l10n.sendCode,
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
    );
  }
}
