import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/app/dev/dev_tools.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// Opens the workspace sheet: every company the person works with, their
/// Personal workspace, and log out. Choosing one switches at once.
Future<void> showWorkspaceSheet(BuildContext context) async {
  final cubit = context.read<WorkspaceCubit>();
  final auth = context.read<AuthRepository>();
  final showDevTools = context.read<AppConfig>().showDevTools;
  final state = cubit.state;
  if (state is! WorkspaceReady) return;
  final l10n = context.l10n;
  await showSolaSheet<void>(
    context: context,
    title: l10n.workspaces,
    doneLabel: l10n.done2,
    builder: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        SolaGroup(
          children: [
            for (final option in state.options)
              _WorkspaceRow(
                workspace: option,
                account: state.account,
                selected: option == state.current,
                onTap: () {
                  Navigator.of(sheet).pop();
                  unawaited(cubit.choose(option));
                },
              ),
          ],
        ),
        SolaText(
          l10n.workspacesNote,
          style: SolaTextStyle.meta,
          color: SolaColors.muted,
        ),
        SolaButton(
          key: const Key('workspace_log_out'),
          label: l10n.logOut,
          variant: SolaButtonVariant.white,
          icon: SolaIcons.logOut,
          onPressed: () {
            Navigator.of(sheet).pop();
            unawaited(auth.logOut());
          },
        ),
        if (showDevTools) const DevToolsSection(),
      ],
    ),
  );
}

class _WorkspaceRow extends StatelessWidget {
  const new({
    required this.workspace,
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final Workspace workspace;
  final Account account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trailing = selected
        ? const SolaIcon(SolaIcons.check)
        : const SolaIcon(
            SolaIcons.chevronRight,
            size: 18,
            color: SolaColors.faint,
          );
    return switch (workspace) {
      PersonalWorkspace() => SolaListRow(
        key: const Key('workspace_personal'),
        title: l10n.personal,
        subtitle: l10n.personalSub,
        leading: SolaAvatar(initials: account.initials),
        trailing: trailing,
        semanticsLabel: selected ? '${l10n.personal}, ${l10n.selected}' : null,
        onTap: onTap,
      ),
      MemberWorkspace(
        :final orgName,
        :final role,
        :final orgStatus,
        :final orgInitials,
      ) =>
        SolaListRow(
          key: ValueKey('workspace_${workspace.id}'),
          title: orgName,
          subtitle: orgStatus == OrgStatus.active
              ? role.label(l10n)
              : '${role.label(l10n)} · ${orgStatus.label(l10n)}',
          leading: SolaAvatar(
            initials: orgInitials,
            color: SolaColors.brown,
            foreground: SolaColors.cream,
          ),
          trailing: trailing,
          semanticsLabel: selected ? '$orgName, ${l10n.selected}' : null,
          onTap: onTap,
        ),
    };
  }
}
