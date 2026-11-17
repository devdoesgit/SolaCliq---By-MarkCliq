import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/workspace/view/company_logo.dart';
import 'package:solacliq/workspace/view/workspace_sheet.dart';

/// The top of every home: the person's avatar (their profile), the
/// company's logo, an optional eyebrow and the title in the middle with an
/// optional workspace line, and the bell. Switching workspaces lives on the
/// Profile tab, not here (owner, 2026-11-18).
class HomeHeader extends StatelessWidget {
  const new({
    required this.initials,
    required this.title,
    this.eyebrow,
    this.logoUrl,
    this.workspaceLine,
    this.onAvatar,
    this.onBell,
    this.unread = false,
    super.key,
  });

  final String initials;

  /// The line above the title, like "Good morning". None on the worker
  /// home, whose week strip already shows the day.
  final String? eyebrow;
  final String title;

  /// The company's logo, shown above the titles: the company's own look
  /// in its people's app (F15).
  final String? logoUrl;

  /// "Arka Solar · Worker": where the person is. Plain text; workspaces
  /// are switched from the Profile tab.
  final String? workspaceLine;

  /// What the avatar opens: the Profile tab. The workspace sheet by default,
  /// for the one home with no tabs (a company that isn't active), where
  /// it's the only way out.
  final VoidCallback? onAvatar;

  /// What the bell opens; "coming soon" by default.
  final VoidCallback? onBell;

  /// Shows a dot on the bell.
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final line = workspaceLine;
    final logo = logoUrl;
    final eyebrow = this.eyebrow;
    final titles = Column(
      spacing: SolaSpace.space2,
      children: [
        if (logo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: SolaSpace.space4),
            child: CompanyLogo(url: logo),
          ),
        if (eyebrow != null)
          SolaText(
            eyebrow,
            style: SolaTextStyle.eyebrow,
            color: SolaColors.muted,
          ),
        SolaText(
          title,
          style: SolaTextStyle.navTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (line != null)
          SolaText(
            line,
            style: SolaTextStyle.meta,
            color: SolaColors.muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: SolaSpace.space6),
      child: Row(
        children: [
          SolaTappable(
            key: const Key('home_profile'),
            identifier: 'home_profile',
            semanticsLabel: onAvatar == null
                ? l10n.profileAndWorkspaces
                : l10n.tabProfile,
            onTap: onAvatar ?? () => unawaited(showWorkspaceSheet(context)),
            // The 40px avatar inside a full tap target.
            builder: (context, state) => SizedBox.square(
              dimension: SolaSize.tapMin,
              child: Center(
                child: SolaAvatar(initials: initials, size: SolaSize.navButton),
              ),
            ),
          ),
          Expanded(child: titles),
          // No bell where there is nothing to notify yet (a company that
          // isn't active).
          if (onBell case final bell?)
            SolaCircleButton(
              key: const Key('home_bell'),
              icon: SolaIcons.bell,
              semanticsLabel: unread
                  ? l10n.notificationsUnread
                  : l10n.notifications,
              badge: unread,
              onPressed: bell,
            ),
        ],
      ),
    );
  }
}
