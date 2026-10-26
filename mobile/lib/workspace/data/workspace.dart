import 'package:equatable/equatable.dart';
import 'package:solacliq/auth/data/account.dart';

/// Who the person is acting as in the app: themselves (their quotes and
/// their own solar), or a worker, agent or customer of one company. Each
/// `(company, role)` pair is its own workspace, so screens never mix one
/// company's data with another's. Nobody picks a role at login: workspaces
/// come from the companies that added them.
sealed class Workspace extends Equatable {
  const new();

  /// Stable id, remembered on the phone to reopen the same workspace.
  String get id;

  @override
  List<Object> get props => [id];
}

/// The person's own account: quotes and their own solar.
final class PersonalWorkspace extends Workspace {
  const new();

  @override
  String get id => 'personal';
}

/// A worker, agent or customer of one company.
final class MemberWorkspace extends Workspace {
  const new(this.membership);

  final AccountMembership membership;

  String get orgId => membership.orgId;
  String get orgName => membership.orgName;
  OrgRole get role => membership.role;
  OrgStatus get orgStatus => membership.orgStatus;
  String? get orgPhone => membership.orgPhone;

  /// Sales who earn a commission on each customer they add.
  bool get earnsCommission =>
      role == OrgRole.agent && membership.payType != PayType.salary;

  /// Up to two initials of the company, for its avatar.
  String get orgInitials => companyInitials(orgName);

  @override
  String get id => '${membership.orgId}:${membership.role.name}';

  @override
  List<Object> get props => [membership];
}

/// The company workspaces [account] can use in the app. Org admins work on
/// the website only, so their memberships are left out.
List<MemberWorkspace> companyWorkspaces(Account account) => [
  for (final m in account.memberships)
    if (m.role != OrgRole.orgAdmin) MemberWorkspace(m),
];

/// Up to two initials of a company name, ignoring notes in brackets.
String companyInitials(String name) {
  final words = name
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty);
  return words.take(2).map((w) => w[0].toUpperCase()).join();
}
