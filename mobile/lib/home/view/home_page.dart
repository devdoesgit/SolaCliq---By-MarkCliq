import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/home/view/member_shells.dart';
import 'package:solacliq/home/view/org_home.dart';
import 'package:solacliq/home/view/personal_home.dart';
import 'package:solacliq/home/view/worker_shell.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// The signed-in home for the workspace in use: Personal, or a company
/// home for the person's role there.
class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: BlocBuilder<WorkspaceCubit, WorkspaceState>(
        // Keep the last home on screen while the router moves away.
        buildWhen: (_, state) => state is WorkspaceReady,
        builder: (context, state) => switch (state) {
          // A new workspace starts fresh, with its own screen state.
          WorkspaceReady(:final account, :final current, :final canSwitch) =>
            switch (current) {
              PersonalWorkspace() => PersonalHome(
                key: ValueKey(current.id),
                account: account,
              ),
              MemberWorkspace(
                role: OrgRole.worker,
                orgStatus: OrgStatus.active,
              ) =>
                WorkerShell(
                  key: ValueKey(current.id),
                  account: account,
                  workspace: current,
                  canSwitch: canSwitch,
                ),
              MemberWorkspace(
                role: OrgRole.agent,
                orgStatus: OrgStatus.active,
              ) =>
                SalesShell(
                  key: ValueKey(current.id),
                  account: account,
                  workspace: current,
                  canSwitch: canSwitch,
                ),
              MemberWorkspace(
                role: OrgRole.customer,
                orgStatus: OrgStatus.active,
              ) =>
                CustomerShell(
                  key: ValueKey(current.id),
                  account: account,
                  workspace: current,
                  canSwitch: canSwitch,
                ),
              MemberWorkspace() => OrgHome(
                key: ValueKey(current.id),
                account: account,
                workspace: current,
                canSwitch: canSwitch,
              ),
            },
          _ => const Scaffold(),
        },
      ),
    );
  }
}
