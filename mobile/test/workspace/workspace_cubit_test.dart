import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

void main() {
  late MockAuthRepository auth;
  late StreamController<AuthStatus> statuses;
  late FakeWorkspaceStore store;

  final worker = testMembership();
  final agent = testMembership(
    orgId: 'o2',
    orgName: 'Sample Rooftops',
    role: OrgRole.agent,
  );
  final admin = testMembership(orgId: 'o3', role: OrgRole.orgAdmin);

  setUp(() {
    auth = MockAuthRepository();
    statuses = StreamController<AuthStatus>.broadcast();
    store = FakeWorkspaceStore();
    when(() => auth.statusChanges).thenAnswer((_) => statuses.stream);
    when(() => auth.status).thenReturn(const AuthUnknown());
  });

  tearDown(() => statuses.close());

  /// A cubit whose auth status starts at [initial].
  Future<WorkspaceCubit> build(AuthStatus initial) async {
    when(() => auth.status).thenReturn(initial);
    final cubit = WorkspaceCubit(auth: auth, store: store);
    addTearDown(cubit.close);
    await pumpEventQueue();
    return cubit;
  }

  Future<void> emitAuth(AuthStatus status) async {
    statuses.add(status);
    await pumpEventQueue();
  }

  AuthAuthenticated signedIn(List<AccountMembership> memberships) =>
      AuthAuthenticated(testAccount(memberships: memberships));

  group(WorkspaceCubit, () {
    test('waits while the login is being read', () async {
      final cubit = await build(const AuthUnknown());
      expect(cubit.state, const WorkspaceLoading());
    });

    test('no memberships: Personal, nothing to switch to', () async {
      final cubit = await build(signedIn(const []));
      expect(
        cubit.state,
        isA<WorkspaceReady>()
            .having((s) => s.current, 'current', const PersonalWorkspace())
            .having((s) => s.canSwitch, 'canSwitch', false),
      );
    });

    test('only org admin: the website notice', () async {
      final cubit = await build(signedIn([admin]));
      expect(cubit.state, isA<WorkspaceAdminOnly>());
      expect((cubit.state as WorkspaceAdminOnly).orgNames, ['Example Solar']);
    });

    test('org admin roles are never offered in the app', () async {
      final cubit = await build(signedIn([admin, worker]));
      final state = cubit.state as WorkspaceReady;
      expect(state.current, MemberWorkspace(worker));
      expect(state.options, [
        MemberWorkspace(worker),
        const PersonalWorkspace(),
      ]);
    });

    test('opens the first company, and remembers a choice', () async {
      final cubit = await build(signedIn([worker, agent]));
      expect((cubit.state as WorkspaceReady).current, MemberWorkspace(worker));

      await cubit.choose(MemberWorkspace(agent));
      expect((cubit.state as WorkspaceReady).current, MemberWorkspace(agent));
      expect(store.id, 'o2:agent');
    });

    test('opens the remembered workspace', () async {
      store.id = 'o2:agent';
      final cubit = await build(signedIn([worker, agent]));
      expect((cubit.state as WorkspaceReady).current, MemberWorkspace(agent));
    });

    test('a remembered workspace that is gone opens the first', () async {
      store.id = 'o9:agent';
      final cubit = await build(signedIn([worker, agent]));
      expect((cubit.state as WorkspaceReady).current, MemberWorkspace(worker));
    });

    test('an account update keeps the workspace in use', () async {
      final cubit = await build(signedIn([worker, agent]));
      await cubit.choose(MemberWorkspace(agent));
      final newer = testMembership(orgId: 'o4', orgName: 'Demo Power');
      await emitAuth(signedIn([worker, agent, newer]));
      final state = cubit.state as WorkspaceReady;
      expect(state.current, MemberWorkspace(agent));
      expect(state.options, hasLength(4));
    });

    test('another person signing in opens their first company', () async {
      final cubit = await build(signedIn([worker]));
      await cubit.choose(const PersonalWorkspace());
      await emitAuth(
        AuthAuthenticated(testAccount(id: 'u2', memberships: [agent])),
      );
      expect((cubit.state as WorkspaceReady).current, MemberWorkspace(agent));
    });

    test('a status change on the current company shows at once', () async {
      final cubit = await build(signedIn([worker]));
      final suspended = testMembership(status: OrgStatus.suspended);
      await emitAuth(signedIn([suspended]));
      final current = (cubit.state as WorkspaceReady).current;
      expect((current as MemberWorkspace).orgStatus, OrgStatus.suspended);
    });

    test('removed from the company in use: opens the first left', () async {
      final cubit = await build(signedIn([worker, agent]));
      await cubit.choose(MemberWorkspace(agent));
      await emitAuth(signedIn([worker]));
      expect((cubit.state as WorkspaceReady).current, MemberWorkspace(worker));
    });

    test('chooseOrg waits for the account that has the company', () async {
      final cubit = await build(signedIn(const []));
      final choosing = cubit.chooseOrg(worker.orgId);
      await emitAuth(signedIn([worker]));
      await choosing;
      expect((cubit.state as WorkspaceReady).current, MemberWorkspace(worker));
    });

    test('log out forgets the choice', () async {
      final cubit = await build(signedIn([worker, agent]));
      await cubit.choose(MemberWorkspace(agent));
      await emitAuth(const AuthUnauthenticated());
      expect(cubit.state, const WorkspaceSignedOut());
      expect(store.id, isNull);

      // A different person logging in on this phone starts afresh.
      await emitAuth(signedIn([worker, agent]));
      expect((cubit.state as WorkspaceReady).current, MemberWorkspace(worker));
    });

    test('choose ignores a workspace not on offer', () async {
      final cubit = await build(signedIn([worker, agent]));
      final stranger = testMembership(orgId: 'o9');
      await cubit.choose(MemberWorkspace(stranger));
      expect((cubit.state as WorkspaceReady).current, MemberWorkspace(worker));
      expect(store.id, isNull);
    });

    test('a slow store read never applies a stale status', () async {
      final slow = _SlowStore();
      when(() => auth.status).thenReturn(signedIn([worker, agent]));
      final cubit = WorkspaceCubit(auth: auth, store: slow);
      addTearDown(cubit.close);
      // Signed out before the remembered workspace was read.
      statuses.add(const AuthUnauthenticated());
      await pumpEventQueue();
      slow.complete('o1:worker');
      await pumpEventQueue();
      expect(cubit.state, const WorkspaceSignedOut());
    });
  });

  group('MemberWorkspace', () {
    test('id joins company and role', () {
      expect(MemberWorkspace(agent).id, 'o2:agent');
      expect(const PersonalWorkspace().id, 'personal');
    });
  });
}

class _SlowStore extends FakeWorkspaceStore {
  final _read = Completer<String?>();

  void complete(String? id) => _read.complete(id);

  @override
  Future<String?> read() => _read.future;
}
