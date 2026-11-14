import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/workspace/data/workspace.dart';
import 'package:solacliq/workspace/view/workspace_sheet.dart';

/// In place of a company home when the company isn't active (pending
/// approval, suspended or rejected): what is going on, a way to check
/// again, and other workspaces.
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
    final (title, body, tone) = switch (widget.workspace.orgStatus) {
      OrgStatus.suspended => (
        l10n.suspendedTitle,
        l10n.suspendedBody(org),
        SolaTone.danger,
      ),
      OrgStatus.rejected => (
        l10n.rejectedTitle,
        l10n.rejectedBody(org),
        SolaTone.danger,
      ),
      OrgStatus.pending || OrgStatus.active => (
        l10n.pendingTitle,
        l10n.pendingBody(org),
        SolaTone.neutral,
      ),
    };
    // A rejection is final: checking again can't change it.
    final canChange = widget.workspace.orgStatus != OrgStatus.rejected;
    return Padding(
      padding: const EdgeInsets.only(top: SolaSpace.space26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SolaSpace.space14,
        children: [
          SolaNotice(title: title, body: body, tone: tone),
          if (canChange)
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
