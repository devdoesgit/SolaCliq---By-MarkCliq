import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/app/dev/mock_persona.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/home/view/home_header.dart';
import 'package:solacliq/invites/cubit/invites_cubit.dart';
import 'package:solacliq/invites/data/invite_repository.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// The home of a person with no company, or of anyone in their Personal
/// workspace: invites waiting, a free solar quote, and how to get added by
/// an installer.
class PersonalHome extends StatelessWidget {
  const new({required this.account, super.key});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = InvitesCubit(context.read<InviteRepository>());
        unawaited(cubit.load());
        return cubit;
      },
      child: PersonalHomeView(account: account),
    );
  }
}

class PersonalHomeView extends StatefulWidget {
  const new({required this.account, super.key});

  final Account account;

  @override
  State<PersonalHomeView> createState() => _PersonalHomeViewState();
}

class _PersonalHomeViewState extends State<PersonalHomeView> {
  MockPersonaInterceptor? _mock;

  @override
  void initState() {
    super.initState();
    // Development: the "invite waiting" switch reloads the banner.
    if (context.read<AppConfig>().showDevTools) {
      _mock = context.read<MockPersonaInterceptor>()
        ..inviteWaiting.addListener(_reload);
    }
  }

  void _reload() => unawaited(context.read<InvitesCubit>().load());

  @override
  void dispose() {
    _mock?.inviteWaiting.removeListener(_reload);
    super.dispose();
  }

  void _onTab(int index) {
    switch (index) {
      case 1 || 2:
        unawaited(context.push(AppRoutes.quote));
      case 3:
        unawaited(context.push(AppRoutes.learn));
      case 4:
        unawaited(context.push(AppRoutes.profile));
    }
  }

  /// The greeting for the time of day.
  String _greeting(AppLocalizations l10n) => switch (DateTime.now().hour) {
    < 12 => l10n.goodMorning,
    < 17 => l10n.goodAfternoon,
    _ => l10n.goodEvening,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final account = widget.account;
    final invites = context.watch<InvitesCubit>().state;
    return RefreshIndicator(
      color: SolaColors.ink,
      onRefresh: () => context.read<InvitesCubit>().load(),
      child: SolaScreen(
        bottomOverlaps: true,
        bottom: SolaTabBar(
          selectedIndex: 0,
          onSelected: _onTab,
          items: [
            SolaTabItem(
              key: const ValueKey('tab_home'),
              label: l10n.tabHome,
              icon: SolaIcons.home,
            ),
            SolaTabItem(
              key: const ValueKey('tab_quotes'),
              label: l10n.tabQuotes,
              icon: SolaIcons.sun,
            ),
            SolaTabItem(
              key: const ValueKey('tab_get_quote'),
              label: l10n.getAQuote,
              icon: SolaIcons.plus,
              raised: true,
            ),
            SolaTabItem(
              key: const ValueKey('tab_learn'),
              label: l10n.tabLearn,
              icon: SolaIcons.book,
            ),
            SolaTabItem(
              key: const ValueKey('tab_profile'),
              label: l10n.tabProfile,
              icon: SolaIcons.user,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SolaSpace.space14,
          children: [
            HomeHeader(
              initials: account.initials,
              eyebrow: _greeting(l10n),
              title: account.firstName,
              onBell: () => unawaited(context.push(AppRoutes.notifications)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: SolaSpace.space22),
              child: SolaHeadline(
                value: l10n.subsidyHeadline,
                label: l10n.subsidyLabel,
                detail: l10n.subsidyDetail,
              ),
            ),
            for (final invite in invites) _InviteBanner(invite: invite),
            SolaPhotoCard(
              photo: SolaPhotos.quoteHome,
              eyebrow: l10n.freeQuote,
              title: l10n.quoteCardTitle2,
              action: SolaButton(
                key: const Key('home_get_quote'),
                label: l10n.getAQuote,
                variant: SolaButtonVariant.cream,
                compact: true,
                expand: false,
                onPressed: () => unawaited(context.push(AppRoutes.quote)),
              ),
            ),
            SolaGroup(
              children: [
                SolaListRow(
                  key: const Key('home_typical_system'),
                  title: l10n.typicalSystem,
                  subtitle: l10n.typicalSystemDetail,
                  leading: const SolaThumb(photo: SolaPhotos.quoteHome),
                  trailing: SolaPill(l10n.guide),
                  onTap: () => unawaited(context.push(AppRoutes.learn)),
                ),
                SolaListRow(
                  key: const Key('home_have_installer'),
                  title: l10n.haveInstaller,
                  subtitle: l10n.haveInstallerDetail,
                  leading: const SolaAvatar(
                    icon: SolaIcons.users,
                    color: SolaColors.tan,
                  ),
                  onTap: () => unawaited(_showInstallerNote(account.email)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInstallerNote(String email) {
    final l10n = context.l10n;
    return showSolaSheet<void>(
      context: context,
      title: l10n.haveInstallerTitle,
      doneLabel: l10n.done2,
      builder: (_) => Padding(
        padding: const EdgeInsets.only(bottom: SolaSpace.space8),
        child: SolaText(
          l10n.haveInstallerBody(email),
          style: SolaTextStyle.bodyLg,
          color: SolaColors.muted,
        ),
      ),
    );
  }
}

/// "Company invited you · to join as a Worker", with Review.
class _InviteBanner extends StatelessWidget {
  const new({required this.invite});

  final Invite invite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = l10n.invitedYou(invite.orgName);
    final line = l10n.inviteLine(invite.role.label(l10n));
    return Semantics(
      liveRegion: true,
      child: SolaTappable(
        key: ValueKey('invite_review_${invite.id}'),
        identifier: 'invite_review_${invite.id}',
        semanticsLabel: '$title, $line. ${l10n.review}',
        onTap: () => unawaited(
          context.push(AppRoutes.inviteDetail(invite.id), extra: invite),
        ),
        builder: (context, state) => SolaCard(
          radius: SolaRadius.radius20,
          padding: const EdgeInsets.symmetric(
            horizontal: SolaSpace.space14,
            vertical: SolaSpace.space12,
          ),
          child: Row(
            spacing: SolaSpace.space12,
            children: [
              SolaAvatar(
                initials: companyInitials(invite.orgName),
                size: SolaSize.navButton,
                color: SolaColors.brown,
                foreground: SolaColors.cream,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SolaText(title, style: SolaTextStyle.bodyStrong),
                    SolaText(
                      line,
                      style: SolaTextStyle.meta,
                      color: SolaColors.muted,
                    ),
                  ],
                ),
              ),
              SolaPill(l10n.review, tone: SolaTone.dark),
            ],
          ),
        ),
      ),
    );
  }
}
