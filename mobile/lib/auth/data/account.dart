import 'package:equatable/equatable.dart';

/// The org's approval state.
enum OrgStatus { pending, active, suspended }

/// What a person does in an org.
enum OrgRole { orgAdmin, worker, agent, customer }

/// How an agent (shown as Sales) is paid: a commission on each customer
/// they add, or a salary with no commission step.
enum PayType { commission, salary }

/// A person's role in one org.
class AccountMembership extends Equatable {
  const new({
    required this.orgId,
    required this.orgName,
    required this.orgStatus,
    required this.role,
    this.payType,
    this.orgPhone,
  });

  final String orgId;
  final String orgName;
  final OrgStatus orgStatus;
  final OrgRole role;

  /// Agents only.
  final PayType? payType;

  /// The company's number, ten digits, for its people to call.
  final String? orgPhone;

  @override
  List<Object?> get props => [
    orgId,
    orgName,
    orgStatus,
    role,
    payType,
    orgPhone,
  ];
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
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final bool isPlatformAdmin;
  final List<AccountMembership> memberships;

  /// Mobile number, 10 digits, if the person gave one.
  final String? phone;

  /// First name, for greetings.
  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  /// Up to two initials, for avatars.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    isPlatformAdmin,
    memberships,
    phone,
  ];
}
