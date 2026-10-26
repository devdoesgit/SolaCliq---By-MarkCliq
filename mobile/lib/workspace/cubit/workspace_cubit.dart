import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/workspace/cubit/workspace_state.dart';
import 'package:solacliq/workspace/data/workspace.dart';
import 'package:solacliq/workspace/data/workspace_store.dart';

export 'workspace_state.dart';

/// Turns the sign-in status into the workspace the app shows, and
/// remembers the person's choice on the phone.
///
/// Everyone has their Personal workspace, plus one per company role
/// (worker, agent, customer). The app opens the one in use, else the
/// remembered one, else their first company, else Personal. Someone who is
/// only an org admin gets the website notice.
///
/// When the account changes (a new membership, a removal) the current
/// workspace is kept if it still exists. A different person signing in
/// (or, in development, another mock person) starts from their first
/// company instead.
class WorkspaceCubit extends Cubit<WorkspaceState> {
  new({required AuthRepository auth, required this._store})
    : super(const WorkspaceLoading()) {
    _subscription = auth.statusChanges.listen(_onAuth);
    unawaited(_onAuth(auth.status));
  }

  final WorkspaceStore _store;
  late final StreamSubscription<AuthStatus> _subscription;

  /// The workspace to prefer, read from the store once.
  Future<String?>? _preferred;

  /// Bumped on every status change, so a slow store read can't apply an
  /// old status over a newer one.
  int _generation = 0;

  Future<void> _onAuth(AuthStatus status) async {
    final generation = ++_generation;
    switch (status) {
      case AuthUnknown():
        emit(const WorkspaceLoading());
      case AuthUnauthenticated():
        _preferred = Future.value();
        emit(const WorkspaceSignedOut());
        await _store.clear();
      case AuthAuthenticated(:final account):
        final current = state;
        final preferred = switch (current) {
          WorkspaceReady(account: Account(:final id), current: final w)
              when id == account.id =>
            w.id,
          WorkspaceReady() => null,
          _ => await (_preferred ??= _store.read()),
        };
        if (generation != _generation || isClosed) return;
        emit(_resolve(account, preferred));
    }
  }

  /// Switches to [workspace], one of the options on offer.
  Future<void> choose(Workspace workspace) async {
    final current = state;
    if (current is! WorkspaceReady || !current.options.contains(workspace)) {
      return;
    }
    _preferred = Future.value(workspace.id);
    emit(WorkspaceReady(current.account, workspace, current.options));
    await _store.write(workspace.id);
  }

  /// Switches to the workspace for [orgId], once the account has it (just
  /// after accepting an invite).
  Future<void> chooseOrg(String orgId) async {
    bool hasOrg(WorkspaceState state) =>
        state is WorkspaceReady &&
        state.options.any((o) => o is MemberWorkspace && o.orgId == orgId);
    // The new account reaches this cubit through the auth stream, a moment
    // after the caller applied it.
    final ready = hasOrg(state)
        ? state
        : await stream
              .firstWhere(hasOrg)
              .timeout(const Duration(seconds: 5), onTimeout: () => state);
    if (ready is! WorkspaceReady) return;
    for (final option in ready.options) {
      if (option is MemberWorkspace && option.orgId == orgId) {
        return await choose(option);
      }
    }
  }

  static WorkspaceState _resolve(Account account, String? preferredId) {
    final companies = companyWorkspaces(account);
    final isAdmin = account.memberships.any((m) => m.role == OrgRole.orgAdmin);
    if (companies.isEmpty && isAdmin) return WorkspaceAdminOnly(account);
    final options = <Workspace>[...companies, const PersonalWorkspace()];
    for (final option in options) {
      if (option.id == preferredId) {
        return WorkspaceReady(account, option, options);
      }
    }
    return WorkspaceReady(account, options.first, options);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
