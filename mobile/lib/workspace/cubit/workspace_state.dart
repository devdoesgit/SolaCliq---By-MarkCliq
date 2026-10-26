import 'package:equatable/equatable.dart';
import 'package:solacliq/auth/data/account.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// Where the signed-in person is working, which decides the screen they
/// see.
sealed class WorkspaceState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Reading the stored login or the remembered workspace.
final class WorkspaceLoading extends WorkspaceState {
  const new();
}

final class WorkspaceSignedOut extends WorkspaceState {
  const new();
}

/// Only org admin memberships: their tools are on the website.
final class WorkspaceAdminOnly extends WorkspaceState {
  const new(this.account);

  final Account account;

  /// The companies they administer, for the message.
  List<String> get orgNames => [
    for (final m in account.memberships)
      if (m.role == OrgRole.orgAdmin) m.orgName,
  ];

  @override
  List<Object?> get props => [account];
}

final class WorkspaceReady extends WorkspaceState {
  const new(this.account, this.current, this.options);

  final Account account;
  final Workspace current;

  /// Every workspace the person can switch to, [current] included: their
  /// companies first, then Personal.
  final List<Workspace> options;

  bool get canSwitch => options.length > 1;

  @override
  List<Object?> get props => [account, current, options];
}
