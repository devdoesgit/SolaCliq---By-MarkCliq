import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/view/customers_tab.dart';
import 'package:solacliq/customers/view/earnings_tab.dart';
import 'package:solacliq/home/view/org_home.dart';
import 'package:solacliq/install/view/payments_tab.dart';
import 'package:solacliq/install/view/track_tab.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/notifications/view/notifications_page.dart';
import 'package:solacliq/profile/view/profile_tab.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// A tab of a role's bar: a page kept alive under the bar, or (raised) an
/// action such as adding a customer.
class _Tab {
  const new({
    required this.key,
    required this.label,
    required this.icon,
    this.page,
    this.onTap,
  });

  final String key;
  final String label;
  final SolaIcons icon;
  final Widget? page;
  final VoidCallback? onTap;
}

/// Pages under one tab bar; each keeps its place while another is shown.
class _Shell extends StatelessWidget {
  const new({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  final List<_Tab> tabs;

  /// The page shown, by key.
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final pages = [
      for (final t in tabs)
        if (t.page != null) t,
    ];
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: pages.indexWhere((t) => t.key == selected),
        children: [for (final t in pages) t.page!],
      ),
      bottomNavigationBar: SolaTabBar(
        items: [
          for (final t in tabs)
            SolaTabItem(
              key: ValueKey('tab_${t.key}'),
              label: t.label,
              icon: t.icon,
              raised: t.page == null,
            ),
        ],
        selectedIndex: tabs.indexWhere((t) => t.key == selected),
        onSelected: (i) => switch (tabs[i]) {
          _Tab(:final onTap?) => onTap(),
          final t => onSelect(t.key),
        },
      ),
    );
  }
}

/// A Sales person's app: home, customers, add a customer, earnings (or,
/// salaried, alerts) and profile.
class SalesShell extends StatefulWidget {
  const new({
    required this.account,
    required this.workspace,
    required this.canSwitch,
    super.key,
  });

  final Account account;
  final MemberWorkspace workspace;
  final bool canSwitch;

  @override
  State<SalesShell> createState() => _SalesShellState();
}

class _SalesShellState extends State<SalesShell> {
  String _tab = 'home';
  CustomerFilter _filter = CustomerFilter.all;
  final _customers = GlobalKey<CustomersTabState>();
  final _earnings = GlobalKey<EarningsTabState>();

  void _go(String tab, {CustomerFilter? filter}) {
    setState(() {
      _tab = tab;
      if (filter != null) _filter = filter;
    });
    // Fresh lists each time a tab is opened.
    switch (tab) {
      case 'customers':
        _customers.currentState?.reload();
      case 'earnings':
        _earnings.currentState?.reload();
    }
  }

  void _open(String action) => switch (action) {
    'fix' => _go('customers', filter: CustomerFilter.fix),
    'review' => _go('customers', filter: CustomerFilter.review),
    'see_all' => _go('customers', filter: CustomerFilter.all),
    'earnings' when widget.workspace.earnsCommission => _go('earnings'),
    'profile' => _go('profile'),
    _ => null,
  };

  Future<void> _add() async {
    await context.push(AppRoutes.addCustomer);
    if (mounted) _customers.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final w = widget.workspace;
    return _Shell(
      selected: _tab,
      onSelect: _go,
      tabs: [
        _Tab(
          key: 'home',
          label: l10n.tabHome,
          icon: SolaIcons.home,
          page: OrgHome(
            account: widget.account,
            workspace: w,
            canSwitch: widget.canSwitch,
            onOpen: _open,
          ),
        ),
        _Tab(
          key: 'customers',
          label: l10n.tabCustomers,
          icon: SolaIcons.users,
          page: CustomersTab(key: _customers, orgId: w.orgId, filter: _filter),
        ),
        _Tab(
          key: 'add_customer',
          label: l10n.tabAddCustomer,
          icon: SolaIcons.plus,
          onTap: () => unawaited(_add()),
        ),
        if (w.earnsCommission)
          _Tab(
            key: 'earnings',
            label: l10n.tabEarnings,
            icon: SolaIcons.wallet,
            page: EarningsTab(key: _earnings, orgId: w.orgId),
          )
        else
          _Tab(
            key: 'alerts',
            label: l10n.tabAlerts,
            icon: SolaIcons.bell,
            page: NotificationsPage(
              orgId: w.orgId,
              background: SolaBackground.stone,
              asTab: true,
            ),
          ),
        _Tab(
          key: 'profile',
          label: l10n.tabProfile,
          icon: SolaIcons.user,
          page: ProfileTab(account: widget.account, workspace: w),
        ),
      ],
    );
  }
}

/// A customer's app: home, track, payments and profile.
class CustomerShell extends StatefulWidget {
  const new({
    required this.account,
    required this.workspace,
    required this.canSwitch,
    super.key,
  });

  final Account account;
  final MemberWorkspace workspace;
  final bool canSwitch;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  String _tab = 'home';
  final _track = GlobalKey<TrackTabState>();
  final _payments = GlobalKey<PaymentsTabState>();

  void _go(String tab) {
    setState(() => _tab = tab);
    switch (tab) {
      case 'track':
        _track.currentState?.reload();
      case 'payments':
        _payments.currentState?.reload();
    }
  }

  void _open(String action) => switch (action) {
    'track' || 'see_all' => _go('track'),
    'payments' || 'savings' || 'bill' => _go('payments'),
    'profile' => _go('profile'),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final w = widget.workspace;
    return _Shell(
      selected: _tab,
      onSelect: _go,
      tabs: [
        _Tab(
          key: 'home',
          label: l10n.tabHome,
          icon: SolaIcons.home,
          page: OrgHome(
            account: widget.account,
            workspace: w,
            canSwitch: widget.canSwitch,
            onOpen: _open,
          ),
        ),
        _Tab(
          key: 'track',
          label: l10n.tabTrack,
          icon: SolaIcons.route,
          page: TrackTab(key: _track, orgId: w.orgId),
        ),
        _Tab(
          key: 'payments',
          label: l10n.tabPayments,
          icon: SolaIcons.wallet,
          page: PaymentsTab(key: _payments, workspace: w),
        ),
        _Tab(
          key: 'profile',
          label: l10n.tabProfile,
          icon: SolaIcons.user,
          page: ProfileTab(
            account: widget.account,
            workspace: w,
            onTab: (tab) => _go(tab.name),
          ),
        ),
      ],
    );
  }
}
