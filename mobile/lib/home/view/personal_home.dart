import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/home/view/home_header.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/notifications/data/notification_repository.dart';

/// The home of a person with no company, or of anyone in their Personal
/// workspace: a free solar quote, and how to get added by an installer.
class PersonalHome extends StatefulWidget {
  const new({required this.account, super.key});

  final Account account;

  @override
  State<PersonalHome> createState() => _PersonalHomeState();
}

class _PersonalHomeState extends State<PersonalHome> {
  // Whether the bell shows its dot: any of the person's own unread.
  bool _unread = false;

  Account get account => widget.account;

  @override
  void initState() {
    super.initState();
    unawaited(_loadUnread());
  }

  /// Asks the server; on failure the bell just shows no dot.
  Future<void> _loadUnread() async {
    try {
      final count = await context.read<NotificationRepository>().unreadCount(
        null,
      );
      if (mounted) setState(() => _unread = count > 0);
    } on AuthFailure {
      return;
    }
  }

  /*
    Opens a screen, and asks for the count again on the way back: reading
    the list clears the dot, and a quote sent there adds a notification
  */
  void _open(String path) => unawaited(
    context.push(path).then((_) {
      if (mounted) unawaited(_loadUnread());
    }),
  );

  void _onTab(BuildContext context, int index) {
    switch (index) {
      case 1 || 2:
        _open(AppRoutes.quote);
      case 3:
        _open(AppRoutes.learn);
      case 4:
        _open(AppRoutes.profile);
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
    return SolaScreen(
      bottomOverlaps: true,
      bottom: SolaTabBar(
        selectedIndex: 0,
        onSelected: (index) => _onTab(context, index),
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
            unread: _unread,
            onBell: () => _open(AppRoutes.notifications),
          ),
          Padding(
            padding: const EdgeInsets.only(top: SolaSpace.space22),
            child: SolaHeadline(
              value: l10n.subsidyHeadline,
              label: l10n.subsidyLabel,
              detail: l10n.subsidyDetail,
            ),
          ),
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
              onPressed: () => _open(AppRoutes.quote),
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
                onTap: () => _open(AppRoutes.learn),
              ),
              SolaListRow(
                key: const Key('home_have_installer'),
                title: l10n.haveInstaller,
                subtitle: l10n.haveInstallerDetail,
                leading: const SolaAvatar(
                  icon: SolaIcons.users,
                  color: SolaColors.tan,
                ),
                onTap: () => unawaited(_showInstallerNote(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showInstallerNote(BuildContext context) {
    final l10n = context.l10n;
    final email = account.email;
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
