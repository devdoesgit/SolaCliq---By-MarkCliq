import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/customers/view/customer_text.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Which customers the list shows.
enum CustomerFilter { all, fix, review, approved }

/// The customers a Sales person added, filtered by where their KYC is,
/// with a search by name or phone.
class CustomersTab extends StatefulWidget {
  const new({required this.orgId, this.filter = CustomerFilter.all, super.key});

  final String orgId;

  /// The filter to show, set by the home's tiles.
  final CustomerFilter filter;

  @override
  State<CustomersTab> createState() => CustomersTabState();
}

class CustomersTabState extends State<CustomersTab> {
  late Future<List<CustomerSummary>> _customers = _fetch();
  late CustomerFilter _filter = widget.filter;
  bool _searching = false;
  String _query = '';

  Future<List<CustomerSummary>> _fetch() =>
      context.read<CustomerRepository>().mine(widget.orgId);

  /// Fetches the list again, as the tab is opened.
  void reload() => setState(() => _customers = _fetch());

  @override
  void didUpdateWidget(CustomersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) _filter = widget.filter;
  }

  bool _shows(CustomerSummary c) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) return false;
    return switch (_filter) {
      CustomerFilter.all => true,
      CustomerFilter.fix => c.kyc == KycStatus.needsFix,
      CustomerFilter.review => c.kyc == KycStatus.inReview,
      CustomerFilter.approved => c.kyc == KycStatus.approved,
    };
  }

  Future<void> _open(CustomerSummary c) async {
    await context.push(AppRoutes.customer(c.id));
    if (mounted) reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RefreshIndicator(
      color: SolaColors.ink,
      onRefresh: () async {
        reload();
        await _customers;
      },
      child: SolaScreen(
        background: SolaBackground.stone,
        bottomOverlaps: true,
        navBar: SolaNavBar(
          title: l10n.tabCustomers,
          trailing: SolaCircleButton(
            key: const Key('customers_search'),
            icon: SolaIcons.search,
            semanticsLabel: l10n.searchLabel,
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SolaSpace.space14,
          children: [
            if (_searching)
              SolaGroup(
                children: [
                  SolaFieldRow(
                    key: const ValueKey('customers_query'),
                    label: l10n.searchLabel,
                    placeholder: l10n.searchCustomers,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            SolaSegmented<CustomerFilter>(
              key: const ValueKey('customers_filter'),
              label: l10n.tabCustomers,
              selected: _filter,
              onChanged: (f) => setState(() => _filter = f),
              choices: [
                SolaChoice(CustomerFilter.all, l10n.filterAll),
                SolaChoice(CustomerFilter.fix, l10n.filterFix),
                SolaChoice(CustomerFilter.review, l10n.statusInReview),
                SolaChoice(CustomerFilter.approved, l10n.statusApproved),
              ],
            ),
            LoadView(
              future: _customers,
              failedTitle: l10n.customersLoadFailed,
              onRetry: reload,
              builder: (context, all) {
                final shown = all.where(_shows).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: SolaSpace.space14,
                  children: [
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: SolaSpace.space26),
                        child: SolaText(
                          l10n.noCustomersMatch,
                          color: SolaColors.muted,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      CustomerGroup(customers: shown, onOpen: _open),
                    SolaText(
                      l10n.customersFooter,
                      style: SolaTextStyle.small,
                      color: SolaColors.muted,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Customers as rows: initials, name, where it stands, KYC pill.
class CustomerGroup extends StatelessWidget {
  const new({
    required this.customers,
    required this.onOpen,
    this.trailing,
    this.subtitle,
    this.title,
    super.key,
  });

  final List<CustomerSummary> customers;
  final ValueChanged<CustomerSummary> onOpen;

  /// Replaces the KYC pill.
  final Widget Function(CustomerSummary)? trailing;

  /// Replaces the server's line.
  final String Function(CustomerSummary)? subtitle;

  /// Replaces the name.
  final String Function(CustomerSummary)? title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SolaGroup(
      children: [
        for (final c in customers)
          SolaListRow(
            key: ValueKey('customer_row_${c.id}'),
            title: title?.call(c) ?? c.name,
            subtitle: subtitle?.call(c) ?? c.detail,
            leading: SolaAvatar(initials: c.initials),
            trailing: trailing?.call(c) ?? c.kyc.pill(l10n),
            onTap: () => onOpen(c),
          ),
      ],
    );
  }
}
