import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/widgets/coming_soon.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/workspace/view/workspace_sheet.dart';

/// The top of every home: the person's avatar (workspaces and log out), an
/// eyebrow and title in the middle with an optional workspace line, and
/// the bell.
class HomeHeader extends StatelessWidget {
  const new({
    required this.initials,
    required this.eyebrow,
    required this.title,
    this.workspaceLine,
    this.onAvatar,
    this.onBell,
    this.unread = false,
    super.key,
  });

  final String initials;
  final String eyebrow;
  final String title;

  /// "Arka Solar · Worker", which opens the workspace sheet.
  final String? workspaceLine;

  /// What the avatar opens; the workspace sheet by default.
  final VoidCallback? onAvatar;

  /// What the bell opens; "coming soon" by default.
  final VoidCallback? onBell;

  /// Shows a dot on the bell.
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final line = workspaceLine;
    final titles = Column(
      spacing: SolaSpace.space2,
      children: [
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
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: SolaSpace.space4,
            children: [
              Flexible(
                child: SolaText(
                  line,
                  style: SolaTextStyle.meta,
                  color: SolaColors.muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SolaIcon(
                SolaIcons.chevronDown,
                size: 14,
                color: SolaColors.muted,
              ),
            ],
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
          Expanded(
            // With a workspace line, the whole block opens the workspaces.
            child: line == null
                ? titles
                : SolaTappable(
                    key: const Key('home_workspace_line'),
                    identifier: 'home_workspace_line',
                    semanticsLabel: '$title, $line',
                    onTap: () => unawaited(showWorkspaceSheet(context)),
                    builder: (context, state) => titles,
                  ),
          ),
          SolaCircleButton(
            key: const Key('home_bell'),
            icon: SolaIcons.bell,
            semanticsLabel: unread
                ? l10n.notificationsUnread
                : l10n.notifications,
            badge: unread,
            onPressed:
                onBell ??
                () => unawaited(showComingSoon(context, l10n.notifications)),
          ),
        ],
      ),
    );
  }
}
