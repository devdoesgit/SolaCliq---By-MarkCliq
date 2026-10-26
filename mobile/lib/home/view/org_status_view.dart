import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/workspace/data/workspace.dart';
import 'package:solacliq/workspace/view/workspace_sheet.dart';

/// In place of a company home when the company is pending approval or
/// suspended: what is going on, a way to check again, and other
/// workspaces.
class OrgStatusView extends StatefulWidget {
  const new({required this.workspace, required this.canSwitch, super.key});

  final MemberWorkspace workspace;
  final bool canSwitch;

  @override
  State<OrgStatusView> createState() => _OrgStatusViewState();
}

class _OrgStatusViewState extends State<OrgStatusView> {
  bool _checking = false;

  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    await context.read<AuthRepository>().refreshAccount(force: true);
    // A change of status replaces this view; otherwise allow another try.
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final org = widget.workspace.orgName;
    final suspended = widget.workspace.orgStatus == OrgStatus.suspended;
    return Padding(
      padding: const EdgeInsets.only(top: SolaSpace.space26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SolaSpace.space14,
        children: [
          SolaNotice(
            title: suspended ? l10n.suspendedTitle : l10n.pendingTitle,
            body: suspended ? l10n.suspendedBody(org) : l10n.pendingBody(org),
            tone: suspended ? SolaTone.danger : SolaTone.neutral,
          ),
          SolaButton(
            key: const Key('status_check_again'),
            label: l10n.checkAgain,
            variant: SolaButtonVariant.white,
            onPressed: _checking ? null : () => unawaited(_checkAgain()),
          ),
          if (widget.canSwitch)
            SolaButton(
              key: const Key('status_switch_workspace'),
              label: l10n.switchWorkspace,
              variant: SolaButtonVariant.text,
              onPressed: () => unawaited(showWorkspaceSheet(context)),
            ),
        ],
      ),
    );
  }
}
