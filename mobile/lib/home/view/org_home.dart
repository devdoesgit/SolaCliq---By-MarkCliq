import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/app/dev/mock_persona.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/coming_soon.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/home/cubit/org_home_cubit.dart';
import 'package:solacliq/home/data/home_repository.dart';
import 'package:solacliq/home/view/home_header.dart';
import 'package:solacliq/home/view/home_parts.dart';
import 'package:solacliq/home/view/org_status_view.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/notifications/view/notifications_page.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// A company home for the person's role there, composed by the server: a
/// worker's week and tasks, an agent's customers and KYC, a customer's
/// install progress or live energy. Each role has its tint and tabs.
class OrgHome extends StatelessWidget {
  const new({
    required this.account,
    required this.workspace,
    required this.canSwitch,
    this.onOpen,
    super.key,
  });

  final Account account;
  final MemberWorkspace workspace;
  final bool canSwitch;

  /// Inside a role's tabs: opens what a tile, a row, "See all" or the
  /// avatar asks for (`see_all`, `profile` or the server's action).
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrgHomeCubit(
        context.read<HomeRepository>(),
        orgId: workspace.orgId,
        role: workspace.role,
      ),
      child: OrgHomeView(
        account: account,
        workspace: workspace,
        canSwitch: canSwitch,
        onOpen: onOpen,
      ),
    );
  }
}

class OrgHomeView extends StatefulWidget {
  const new({
    required this.account,
    required this.workspace,
    required this.canSwitch,
    this.onOpen,
    super.key,
  });

  final Account account;
  final MemberWorkspace workspace;
  final bool canSwitch;

  /// Inside a role's tabs: opens what a tile, a row, "See all" or the
  /// avatar asks for (`see_all`, `profile` or the server's action).
  final ValueChanged<String>? onOpen;

  @override
  State<OrgHomeView> createState() => _OrgHomeViewState();
}

class _OrgHomeViewState extends State<OrgHomeView> {
  MockPersonaInterceptor? _mock;

  @override
  void initState() {
    super.initState();
    if (_active) unawaited(_load());
    // Development: the "handed over" switch reloads the customer's home.
    if (context.read<AppConfig>().showDevTools) {
      _mock = context.read<MockPersonaInterceptor>()
        ..handedOver.addListener(_load);
    }
  }

  @override
  void dispose() {
    _mock?.handedOver.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() => context.read<OrgHomeCubit>().load();

  bool get _active => widget.workspace.orgStatus == OrgStatus.active;

  OrgRole get _role => widget.workspace.role;

  SolaBackground get _background => switch (_role) {
    OrgRole.agent => SolaBackground.stone,
    OrgRole.customer => SolaBackground.sky,
    _ => SolaBackground.sand,
  };

  void _open(String action) {
    if (widget.onOpen case final open?) {
      open(action);
    } else {
      unawaited(showComingSoon(context, action));
    }
  }

  void _onTile(HomeTile tile) {
    if (tile.action case final action?) _open(action);
  }

  /// Rows open their task, customer or documents here; the rest are the
  /// shell's (a tab).
  void _onRow(HomeRow row) {
    final path = switch (row.action) {
      'task' => AppRoutes.task(row.id),
      'customer' => AppRoutes.customer(row.id),
      'documents' => AppRoutes.documents,
      _ => null,
    };
    if (path == null) {
      if (row.action case final action?) _open(action);
      return;
    }
    unawaited(
      context.push(path).then((_) {
        if (mounted) unawaited(_load());
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final workspace = widget.workspace;
    final state = context.watch<OrgHomeCubit>().state;
    final summary = state is OrgHomeLoaded ? state.summary : null;
    // Workers see where they are; others only with more than one company.
    final line =
        _role == OrgRole.worker || companyWorkspaces(widget.account).length > 1
        ? l10n.workspaceLine2(workspace.orgName, _role.label(l10n))
        : null;
    return RefreshIndicator(
      color: SolaColors.ink,
      onRefresh: () async {
        await context.read<AuthRepository>().refreshAccount(force: true);
        if (_active && context.mounted) await _load();
      },
      child: SolaScreen(
        background: _background,
        bottomOverlaps: widget.onOpen != null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(
              initials: widget.account.initials,
              eyebrow: summary?.eyebrow ?? workspace.orgName,
              title: summary?.title ?? widget.account.firstName,
              workspaceLine: line,
              unread: (summary?.unreadNotifications ?? 0) > 0,
              onAvatar: widget.onOpen == null ? null : () => _open('profile'),
              onBell: _active
                  ? () => unawaited(
                      context.push(AppRoutes.notifications).then((tab) {
                        if (tab is NotificationTab) _open(tab.name);
                        if (mounted) unawaited(_load());
                      }),
                    )
                  : null,
            ),
            if (!_active)
              OrgStatusView(workspace: workspace, canSwitch: widget.canSwitch)
            else
              switch (state) {
                OrgHomeLoaded(:final summary) => _Body(
                  summary: summary,
                  role: _role,
                  onTile: _onTile,
                  onRow: _onRow,
                  onSeeAll: () => _open('see_all'),
                ),
                OrgHomeFailed(:final failure) => Padding(
                  padding: const EdgeInsets.only(top: SolaSpace.space26),
                  child: SolaNotice(
                    title: l10n.homeLoadFailed,
                    body: failure.message(l10n),
                    action: SolaButton(
                      key: const Key('home_retry'),
                      label: l10n.retry,
                      variant: SolaButtonVariant.white,
                      compact: true,
                      expand: false,
                      onPressed: () => unawaited(_load()),
                    ),
                  ),
                ),
                OrgHomeLoading() => const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(
                    child: CircularProgressIndicator(color: SolaColors.ink),
                  ),
                ),
              },
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const new({
    required this.summary,
    required this.role,
    required this.onTile,
    this.onRow,
    this.onSeeAll,
  });

  final HomeSummary summary;
  final OrgRole role;
  final ValueChanged<HomeTile> onTile;
  final ValueChanged<HomeRow>? onRow;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final headline = summary.headline;
    final energy = summary.energy;
    final progress = summary.progress;
    final worker = summary.week.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        top: worker ? SolaSpace.space12 : SolaSpace.space14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: worker ? SolaSpace.space12 : SolaSpace.space14,
        children: [
          if (worker) HomeWeek(days: summary.week),
          if (energy != null)
            HomeEnergyView(energy: energy)
          else if (headline != null)
            Padding(
              padding: EdgeInsets.only(
                top: worker ? SolaSpace.space2 : SolaSpace.space18,
              ),
              child: HomeHeadlineView(
                headline: headline,
                style: worker ? SolaTextStyle.numberLg : SolaTextStyle.numberXl,
              ),
            ),
          if (summary.tiles.isNotEmpty)
            HomeTiles(tiles: summary.tiles, onTap: onTile),
          if (progress != null)
            HomeProgressView(
              progress: progress,
              emptyColor: role == OrgRole.customer
                  ? SolaColors.skyTrack
                  : SolaColors.track,
            ),
          HomeList(
            title: summary.listTitle,
            rows: summary.rows,
            onRow: onRow,
            onSeeAll: summary.listTitle == null ? null : onSeeAll,
          ),
        ],
      ),
    );
  }
}
