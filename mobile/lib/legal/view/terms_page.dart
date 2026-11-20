import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/account/widgets/log_out_bar.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/widgets/failure_notice.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/legal/view/terms_agreement.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';

/// "Before you start": shown after login while the person hasn't agreed
/// to the terms in force (F16), so for accounts someone else made and
/// for everyone after the terms change. Nothing else opens until they
/// agree or log out; the router keeps them here.
class TermsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => SubmitCubit(), child: const TermsView());
  }
}

class TermsView extends StatefulWidget {
  const new({super.key});

  @override
  State<TermsView> createState() => _TermsViewState();
}

class _TermsViewState extends State<TermsView> {
  bool _agreed = false;
  String? _error;

  Future<void> _continue() async {
    if (!_agreed) {
      setState(() => _error = context.l10n.errorTerms);
      return;
    }
    final auth = context.read<AuthRepository>();
    await context.read<SubmitCubit>().submit(auth.acceptTerms);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<WorkspaceCubit>().state;
    // Agreed to an older version before: say the terms changed.
    final updated =
        state is WorkspaceNeedsTerms &&
        state.account.termsAcceptedVersion != null;
    final submit = context.watch<SubmitCubit>().state;
    return SolaScreen(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: SolaSpace.space26),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SolaLockup(height: 30, semanticsLabel: l10n.appName),
          ),
          const SizedBox(height: SolaSpace.space12),
          SolaTitleBlock(
            title: l10n.termsTitle,
            subtitle: updated ? l10n.termsUpdatedBody : l10n.termsBody,
            style: SolaTextStyle.largeTitle,
          ),
          const SizedBox(height: SolaSpace.space24),
          if (submit.status == SubmitStatus.failure) ...[
            FailureNotice(state: submit),
            const SizedBox(height: SolaSpace.space14),
          ],
          TermsAgreement(
            value: _agreed,
            error: _error,
            onChanged: (v) => setState(() {
              _agreed = v;
              _error = null;
            }),
          ),
        ],
      ),
      bottom: SolaBottomBar(
        children: [
          SolaButton(
            key: const Key('terms_continue'),
            label: l10n.continueAction,
            onPressed: submit.isSubmitting
                ? null
                : () => unawaited(_continue()),
          ),
          const LogOutButton(),
        ],
      ),
    );
  }
}
