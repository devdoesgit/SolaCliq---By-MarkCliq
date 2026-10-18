import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';

/// The signed-in screen until workers' jobs (F6) and customers'
/// installations (F9) replace it.
class AccountPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    return StreamBuilder<AuthStatus>(
      initialData: auth.status,
      stream: auth.statusChanges,
      builder: (context, snapshot) => switch (snapshot.data) {
        AuthAuthenticated(:final account) => AccountView(account: account),
        // The router is already moving away; keep the frame steady.
        _ => const Scaffold(),
      },
    );
  }
}

class AccountView extends StatefulWidget {
  const new({required this.account, super.key});

  final Account account;

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  bool _loggingOut = false;

  Future<void> _logOut() async {
    setState(() => _loggingOut = true);
    // The router leaves this page once the status changes.
    await context.read<AuthRepository>().logOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final account = widget.account;
    final showDevTools = context.read<AppConfig>().showDevTools;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: SolaSpace.space12,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SolaSpace.space6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: SolaSpace.space2,
                      children: [
                        SolaText(
                          l10n.accountGreeting(account.name),
                          style: SolaTextStyle.h1,
                        ),
                        SolaText(
                          account.email,
                          style: SolaTextStyle.label,
                          color: SolaColors.inkMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SolaSpace.space8),
                  if (account.memberships.isEmpty)
                    SolaNotice(title: l10n.accountEmpty)
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SolaSpace.space6,
                      ),
                      child: SolaText(
                        l10n.accountYourOrgs,
                        style: SolaTextStyle.h2,
                      ),
                    ),
                    const SizedBox(height: SolaSpace.space4),
                    const Divider(),
                    for (final m in account.memberships)
                      SolaListRow(
                        title: m.orgName,
                        meta: m.role.label(l10n),
                        trailing: [
                          SolaStatusPill(
                            label: m.orgStatus.label(l10n),
                            tone: switch (m.orgStatus) {
                              OrgStatus.active => SolaTone.success,
                              OrgStatus.pending => SolaTone.info,
                              OrgStatus.suspended => SolaTone.danger,
                            },
                          ),
                        ],
                      ),
                  ],
                  if (showDevTools) ...[
                    const SizedBox(height: SolaSpace.space8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SolaSpace.space6,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SolaButton(
                          key: const Key('account_open_gallery'),
                          label: l10n.openGallery,
                          variant: SolaButtonVariant.ghost,
                          onPressed: () =>
                              unawaited(context.push(AppRoutes.gallery)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: SolaColors.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(SolaSpace.space6),
                child: SolaButton(
                  key: const Key('account_log_out'),
                  label: l10n.logOut,
                  expand: true,
                  onPressed: _loggingOut ? null : () => unawaited(_logOut()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
