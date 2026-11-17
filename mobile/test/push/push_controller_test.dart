import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/notifications/data/notification_repository.dart';
import 'package:solacliq/notifications/view/notifications_page.dart';
import 'package:solacliq/push/push_controller.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

class _MockGoRouter extends Mock implements GoRouter;

/// Firebase as the controller sees it, driven by the test.
class _FakeMessaging implements PushMessaging {
  bool available = true;
  String? currentToken = 'token-1';
  PushMessage? opening;
  int permissionAsks = 0;
  bool isAllowed = true;
  int settingsOpened = 0;
  final refreshes = StreamController<String>.broadcast();
  final tapped = StreamController<PushMessage>.broadcast();
  final arrivals = StreamController<PushMessage>.broadcast();

  @override
  Future<bool> start() async => available;

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return true;
  }

  @override
  Future<bool> allowed() async => isAllowed;

  @override
  Future<PushMessage?> initialTap() async => opening;

  @override
  Stream<PushMessage> get taps => tapped.stream;

  @override
  Stream<PushMessage> get received => arrivals.stream;

  @override
  Future<void> openSettings() async => settingsOpened++;

  Future<void> close() async {
    await refreshes.close();
    await tapped.close();
    await arrivals.close();
  }
}

void main() {
  late MockAuthRepository auth;
  late StreamController<AuthStatus> statuses;
  late MockNotificationRepository notifications;
  late _MockGoRouter router;
  late _FakeMessaging messaging;

  final worker = testMembership();
  final customer = testMembership(
    orgId: 'o2',
    orgName: 'Sample Rooftops',
    role: OrgRole.customer,
  );
  final ravi = AuthAuthenticated(testAccount(memberships: [worker, customer]));

  setUp(() {
    auth = MockAuthRepository();
    statuses = StreamController<AuthStatus>.broadcast();
    notifications = MockNotificationRepository();
    router = _MockGoRouter();
    messaging = _FakeMessaging();
    when(() => auth.statusChanges).thenAnswer((_) => statuses.stream);
    when(() => auth.status).thenReturn(const AuthUnknown());
    when(() => notifications.registerDevice(any())).thenAnswer((_) async {});
    when(() => router.push<Object?>(any())).thenAnswer((_) async => null);
  });

  tearDown(() async {
    await statuses.close();
    await messaging.close();
  });

  /// A started controller, with auth starting at [initial].
  Future<(PushController, WorkspaceCubit)> start(AuthStatus initial) async {
    when(() => auth.status).thenReturn(initial);
    final workspace = WorkspaceCubit(auth: auth, store: FakeWorkspaceStore());
    final push = PushController(
      messaging: messaging,
      auth: auth,
      notifications: notifications,
      workspace: workspace,
      router: router,
    );
    addTearDown(() async {
      await push.dispose();
      await workspace.close();
    });
    await push.start();
    await pumpEventQueue();
    return (push, workspace);
  }

  Future<void> emitAuth(AuthStatus status) async {
    statuses.add(status);
    await pumpEventQueue();
  }

  group('the token', () {
    test('an app start while logged in sends it, without asking', () async {
      await start(ravi);
      verify(() => notifications.registerDevice('token-1')).called(1);
      expect(messaging.permissionAsks, 0);
    });

    test('logging in asks for permission once, then sends it', () async {
      await start(const AuthUnauthenticated());
      verifyNever(() => notifications.registerDevice(any()));
      await emitAuth(ravi);
      expect(messaging.permissionAsks, 1);
      verify(() => notifications.registerDevice('token-1')).called(1);
    });

    test('an account refresh does not send it again', () async {
      await start(ravi);
      await emitAuth(ravi);
      verify(() => notifications.registerDevice('token-1')).called(1);
    });

    test('someone else logging in on the phone sends it for them', () async {
      await start(ravi);
      await emitAuth(const AuthUnauthenticated());
      await emitAuth(AuthAuthenticated(testAccount(id: '2')));
      verify(() => notifications.registerDevice('token-1')).called(2);
      expect(messaging.permissionAsks, 1);
    });

    test('a new token is sent while logged in, not after', () async {
      await start(ravi);
      messaging.refreshes.add('token-2');
      await pumpEventQueue();
      verify(() => notifications.registerDevice('token-2')).called(1);

      await emitAuth(const AuthUnauthenticated());
      messaging.refreshes.add('token-3');
      await pumpEventQueue();
      verifyNever(() => notifications.registerDevice('token-3'));
    });

    test('a failed save is not a crash', () async {
      when(() => notifications.registerDevice(any()))
          .thenThrow(const AuthFailure(AuthFailureCode.network));
      await start(ravi);
      verify(() => notifications.registerDevice('token-1')).called(1);
    });

    test('no token (no Play services) sends nothing', () async {
      messaging.currentToken = null;
      await start(ravi);
      verifyNever(() => notifications.registerDevice(any()));
    });

    test('a phone without push does nothing at all', () async {
      messaging.available = false;
      await start(ravi);
      verifyNever(() => notifications.registerDevice(any()));
      messaging.tapped.add(const PushMessage(kind: NotificationKind.guide));
      await pumpEventQueue();
      verifyNever(() => router.go(any()));
    });
  });

  group('a tap', () {
    test('opens the task in its company', () async {
      final (_, workspace) = await start(ravi);
      messaging.tapped.add(
        const PushMessage(
          kind: NotificationKind.taskAssigned,
          orgId: 'o1',
          taskId: 't1',
        ),
      );
      await pumpEventQueue();
      expect(
        (workspace.state as WorkspaceReady).current,
        MemberWorkspace(worker),
      );
      verifyInOrder([
        () => router.go(AppRoutes.home),
        () => router.push<Object?>(AppRoutes.task('t1')),
      ]);
    });

    test('switches workspace first when it is another company', () async {
      final (_, workspace) = await start(ravi);
      expect(
        (workspace.state as WorkspaceReady).current,
        MemberWorkspace(worker),
      );
      messaging.tapped.add(
        const PushMessage(
          kind: NotificationKind.expenseApproved,
          orgId: 'o2',
          expenseId: 'e1',
        ),
      );
      await pumpEventQueue();
      expect(
        (workspace.state as WorkspaceReady).current,
        MemberWorkspace(customer),
      );
      verify(() => router.push<Object?>(AppRoutes.expenseDetail('e1')));
    });

    test('with no company opens Personal', () async {
      final (_, workspace) = await start(ravi);
      messaging.tapped.add(const PushMessage(kind: NotificationKind.guide));
      await pumpEventQueue();
      expect(
        (workspace.state as WorkspaceReady).current,
        const PersonalWorkspace(),
      );
      verify(() => router.push<Object?>(AppRoutes.learn));
    });

    test('about a payment asks the home for its tab', () async {
      final (push, _) = await start(ravi);
      messaging.tapped.add(
        const PushMessage(kind: NotificationKind.paymentDue, orgId: 'o2'),
      );
      await pumpEventQueue();
      verify(() => router.go(AppRoutes.home));
      verifyNever(() => router.push<Object?>(any()));
      expect(push.pendingTab.value, NotificationTab.payments);
    });

    test('with nothing to open shows the notifications list', () async {
      await start(ravi);
      messaging.tapped.add(
        const PushMessage(kind: NotificationKind.kycSubmitted, orgId: 'o1'),
      );
      await pumpEventQueue();
      verify(() => router.push<Object?>(AppRoutes.notifications));
    });

    test('for a company the person left does nothing', () async {
      await start(ravi);
      messaging.tapped.add(
        const PushMessage(
          kind: NotificationKind.taskAssigned,
          orgId: 'gone',
          taskId: 't1',
        ),
      );
      await pumpEventQueue();
      verifyNever(() => router.go(any()));
    });

    test('signed out does nothing', () async {
      await start(const AuthUnauthenticated());
      messaging.tapped.add(
        const PushMessage(
          kind: NotificationKind.taskAssigned,
          orgId: 'o1',
          taskId: 't1',
        ),
      );
      await pumpEventQueue();
      verifyNever(() => router.go(any()));
    });

    test('that opened the app from closed is opened at start', () async {
      messaging.opening = const PushMessage(
        kind: NotificationKind.taskAssigned,
        orgId: 'o1',
        taskId: 't9',
      );
      await start(ravi);
      verify(() => router.push<Object?>(AppRoutes.task('t9')));
    });
  });

  test('a push with the app open tells the screens', () async {
    final (push, _) = await start(ravi);
    final arrived = <PushMessage>[];
    final sub = push.arrived.listen(arrived.add);
    addTearDown(sub.cancel);
    const message = PushMessage(kind: NotificationKind.guide);
    messaging.arrivals.add(message);
    await pumpEventQueue();
    expect(arrived, [message]);
  });

  test('settings: whether allowed, and opening Android settings', () async {
    final (push, _) = await start(ravi);
    messaging.isAllowed = false;
    expect(await push.allowed(), isFalse);
    await push.openSettings();
    expect(messaging.settingsOpened, 1);
  });

  group(PushMessage, () {
    test('reads the push data', () {
      expect(
        PushMessage.fromData({
          'notification_id': 'n1',
          'kind': 'task_assigned',
          'org_id': 'o1',
          'task_id': 't1',
        }),
        const PushMessage(
          kind: NotificationKind.taskAssigned,
          notificationId: 'n1',
          orgId: 'o1',
          taskId: 't1',
        ),
      );
    });

    test('an unknown kind or a stranger push is ignored', () {
      expect(PushMessage.fromData({'kind': 'something_new'}), isNull);
      expect(PushMessage.fromData({}), isNull);
    });

    test('opens like the list item it stands for', () {
      const m = PushMessage(
        kind: NotificationKind.commissionChanged,
        customerId: 'c1',
      );
      expect(destination(m.toNotification()), AppRoutes.customer('c1'));
    });
  });
}
