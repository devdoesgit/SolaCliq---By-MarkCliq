import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/auth/widgets/failure_notice.dart';
import 'package:solacliq/invites/data/invite_repository.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// Which of the two buttons ran, so only it shows as busy.
class DeclineCubit extends SubmitCubit;

/// A company's invite: who they are, what the person will be able to do,
/// what the company will see. Accepting opens the new workspace.
class InvitePage extends StatelessWidget {
  const new({required this.invite, super.key});

  final Invite invite;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SubmitCubit()),
        BlocProvider(create: (_) => DeclineCubit()),
      ],
      child: InviteView(invite: invite),
    );
  }
}

class InviteView extends StatelessWidget {
  const new({required this.invite, super.key});

  final Invite invite;

  Future<void> _accept(BuildContext context) async {
    final invites = context.read<InviteRepository>();
    final workspace = context.read<WorkspaceCubit>();
    final router = GoRouter.of(context);
    await context.read<SubmitCubit>().submit(() async {
      await invites.accept(invite.id);
      await workspace.chooseOrg(invite.orgId);
      router.go(AppRoutes.home);
    });
  }

  Future<void> _decline(BuildContext context) async {
    final invites = context.read<InviteRepository>();
    final router = GoRouter.of(context);
    await context.read<DeclineCubit>().submit(() async {
      await invites.decline(invite.id);
      router.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accept = context.watch<SubmitCubit>().state;
    final decline = context.watch<DeclineCubit>().state;
    final busy = accept.isSubmitting || decline.isSubmitting;
    final abilities = switch (invite.role) {
      OrgRole.agent => [
        (SolaIcons.users, l10n.agentCan1, l10n.agentCan1Sub),
        (SolaIcons.file, l10n.agentCan2, l10n.agentCan2Sub),
        (SolaIcons.receipt, l10n.agentCan3, l10n.agentCan3Sub),
      ],
      OrgRole.customer => [
        (SolaIcons.route, l10n.customerCan1, l10n.customerCan1Sub),
        (SolaIcons.wallet, l10n.customerCan2, l10n.customerCan2Sub),
        (SolaIcons.chat, l10n.customerCan3, l10n.customerCan3Sub),
      ],
      _ => [
        (SolaIcons.list, l10n.workerCan1, l10n.workerCan1Sub),
        (SolaIcons.camera, l10n.workerCan2b, l10n.workerCan2Sub),
        (SolaIcons.receipt, l10n.workerCan3b, l10n.workerCan3Sub),
      ],
    };
    return SolaScreen(
      background: SolaBackground.sand,
      navBar: SolaNavBar(
        leading: const BackTo(fallback: AppRoutes.home),
        title: l10n.inviteBandTitle,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: SolaSpace.space10),
          Column(
            spacing: SolaSpace.space10,
            children: [
              SolaAvatar(
                initials: companyInitials(invite.orgName),
                size: 72,
                color: SolaColors.brown,
                foreground: SolaColors.cream,
              ),
              Padding(
                padding: const EdgeInsets.only(top: SolaSpace.space6),
                child: SolaText(
                  l10n.inviteHeadline(invite.orgName),
                  style: SolaTextStyle.titleSm,
                  textAlign: TextAlign.center,
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: SolaSpace.space6,
                runSpacing: SolaSpace.space6,
                children: [
                  SolaPill(invite.role.label(l10n), tone: SolaTone.dark),
                  SolaPill(l10n.invitedByAdmin(invite.invitedBy)),
                ],
              ),
            ],
          ),
          const SizedBox(height: SolaSpace.space22),
          if (accept.status == SubmitStatus.failure) ...[
            FailureNotice(state: accept),
            const SizedBox(height: SolaSpace.space14),
          ],
          if (decline.status == SubmitStatus.failure) ...[
            FailureNotice(state: decline),
            const SizedBox(height: SolaSpace.space14),
          ],
          SolaSectionLabel(l10n.youllBeAbleTo),
          const SizedBox(height: SolaSpace.space10),
          SolaGroup(
            children: [
              for (final (icon, title, detail) in abilities)
                SolaListRow(
                  title: title,
                  subtitle: detail,
                  leading: SolaAvatar(
                    icon: icon,
                    size: SolaSize.navButton,
                    color: SolaColors.tan,
                  ),
                ),
            ],
          ),
          const SizedBox(height: SolaSpace.space12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SolaSpace.space4),
            child: SolaText(
              l10n.invitePrivacy2(invite.orgName),
              style: SolaTextStyle.meta,
              color: SolaColors.muted,
            ),
          ),
        ],
      ),
      bottom: SolaBottomBar(
        children: [
          SolaButton(
            key: const Key('invite_accept'),
            label: l10n.acceptAndJoin,
            onPressed: busy ? null : () => unawaited(_accept(context)),
          ),
          SolaButton(
            key: const Key('invite_decline'),
            label: l10n.decline,
            variant: SolaButtonVariant.text,
            onPressed: busy ? null : () => unawaited(_decline(context)),
          ),
        ],
      ),
    );
  }
}
