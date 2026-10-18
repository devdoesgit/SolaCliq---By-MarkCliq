import 'package:equatable/equatable.dart';

/// The org's approval state.
enum OrgStatus { pending, active, suspended }

/// What a person does in an org.
enum OrgRole { orgAdmin, worker, agent }

/// A person's role in one org.
class AccountMembership extends Equatable {
  const new({
    required this.orgId,
    required this.orgName,
    required this.orgStatus,
    required this.role,
  });

  final String orgId;
  final String orgName;
  final OrgStatus orgStatus;
  final OrgRole role;

  @override
  List<Object> get props => [orgId, orgName, orgStatus, role];
}

/// The signed-in person. The app's own model, so screens never depend on
/// the generated API types.
class Account extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.email,
    required this.isPlatformAdmin,
    required this.memberships,
  });

  final String id;
  final String name;
  final String email;
  final bool isPlatformAdmin;
  final List<AccountMembership> memberships;

  @override
  List<Object> get props => [id, name, email, isPlatformAdmin, memberships];
}
