import 'package:equatable/equatable.dart';
import 'package:solacliq/auth/data/account.dart';

/// Whether someone is signed in.
sealed class AuthStatus extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// Still reading the stored login at start-up.
final class AuthUnknown extends AuthStatus {
  const new();
}

final class AuthAuthenticated extends AuthStatus {
  const new(this.account);

  final Account account;

  @override
  List<Object> get props => [account];
}

final class AuthUnauthenticated extends AuthStatus {
  const new();
}
