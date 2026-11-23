import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/widgets/failure_notice.dart';
import 'package:solacliq/auth/widgets/password_field.dart';
import 'package:solacliq/l10n/l10n.dart';

/*
  Delete account (F18)
  ----------------------------------------------------------------------
  - says what goes and what stays, then asks for the password
  - once done the person is signed out, and the router leaves
*/
class DeleteAccountLink extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SolaTextLink(
        l10n.deleteAccount,
        key: const Key('delete_account'),
        onPressed: () {
          final auth = context.read<AuthRepository>();
          unawaited(
            showSolaSheet<void>(
              context: context,
              title: l10n.deleteAccount,
              doneLabel: l10n.cancel,
              builder: (_) => BlocProvider(
                create: (_) => SubmitCubit(),
                child: _DeleteAccountForm(auth: auth),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeleteAccountForm extends StatefulWidget {
  const new({required this.auth});

  final AuthRepository auth;

  @override
  State<_DeleteAccountForm> createState() => _DeleteAccountFormState();
}

class _DeleteAccountFormState extends State<_DeleteAccountForm> {
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final password = _password.text;
    setState(() {
      _error = password.isEmpty ? l10n.deleteAccountPassword : null;
    });
    if (password.isEmpty) return;
    final sheet = Navigator.of(context);
    await context.read<SubmitCubit>().submit(() async {
      await widget.auth.deleteAccount(password: password);
      if (sheet.mounted && sheet.canPop()) sheet.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SubmitCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        SolaText(l10n.deleteAccountBody, color: SolaColors.muted),
        if (state.status == SubmitStatus.failure) FailureNotice(state: state),
        SolaGroup(
          children: [
            PasswordField(
              key: const ValueKey('delete_account_password'),
              label: l10n.fieldPassword,
              controller: _password,
              error: _error,
              onChanged: (_) => context.read<SubmitCubit>().reset(),
              onSubmitted: (_) => unawaited(_delete()),
            ),
          ],
        ),
        SolaButton(
          key: const Key('delete_account_confirm'),
          label: l10n.deleteAccountConfirm,
          variant: SolaButtonVariant.warn,
          onPressed: state.isSubmitting ? null : () => unawaited(_delete()),
        ),
      ],
    );
  }
}
