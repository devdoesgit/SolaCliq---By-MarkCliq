import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/notifications/data/notification_repository.dart';
import 'package:solacliq/notifications/view/notifications_page.dart';
import 'package:solacliq/push/data/push_messaging.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';

export 'data/push_messaging.dart';

/// Push notifications on the phone (F12).
///
/// - Signed in: sends this install's token to the server (`PUT
///   /me/device`) once per app start and per log in, and again whenever
///   Firebase hands out a new one. Logging out needs nothing: the server
///   stops pushing to a revoked session.
/// - Right after a log in: asks Android for permission to show
///   notifications (13+), once.
/// - Tapped: switches to the push's workspace, then opens what it's about,
///   the way the notifications list does.
/// - Arrived with the app open: no banner; [arrived] tells the screens
///   showing notifications to reload.
class PushController {
  new({
    required this._messaging,
    required this._auth,
    required this._notifications,
    required this._workspace,
    required this._router,
  });

  final PushMessaging _messaging;
  final AuthRepository _auth;
  final NotificationRepository _notifications;
  final WorkspaceCubit _workspace;
  final GoRouter _router;

  final _subscriptions = <StreamSubscription<Object?>>[];
  final _arrived = StreamController<PushMessage>.broadcast();

  /// A home tab a tapped push asked for (the customer's track or payments),
  /// for the shell to open and then clear.
  final ValueNotifier<NotificationTab?> pendingTab = ValueNotifier(null);

  /// The account the token was last sent for; null when signed out.
  String? _registeredFor;
  AuthStatus? _last;

  /// Pushes that arrived while the app was open.
  Stream<PushMessage> get arrived => _arrived.stream;

  Future<void> start() async {
    if (!await _messaging.start()) return;
    _subscriptions
      ..add(_auth.statusChanges.listen((s) => unawaited(_onAuth(s))))
      ..add(_messaging.tokenRefreshes.listen((t) => unawaited(_send(t))))
      ..add(_messaging.taps.listen((m) => unawaited(open(m))))
      ..add(_messaging.received.listen(_arrived.add));
    await _onAuth(_auth.status);
    final first = await _messaging.initialTap();
    if (first != null) await open(first);
  }

  Future<void> _onAuth(AuthStatus status) async {
    final previous = _last;
    _last = status;
    switch (status) {
      case AuthUnknown():
        return;
      case AuthUnauthenticated():
        _registeredFor = null;
      case AuthAuthenticated(:final account):
        if (_registeredFor == account.id) return;
        _registeredFor = account.id;
        // Only straight after logging in, not on every app start.
        if (previous is AuthUnauthenticated) {
          await _messaging.requestPermission();
        }
        if (await _messaging.token() case final token?) await _send(token);
    }
  }

  Future<void> _send(String token) async {
    if (_last is! AuthAuthenticated) return;
    try {
      await _notifications.registerDevice(token);
    } on AuthFailure catch (e) {
      // Pushes wait for the next app start; the in-app list still works.
      log('Push token not saved: ${e.code}');
    }
  }

  /// Opens what [message] is about, in its workspace.
  Future<void> open(PushMessage message) async {
    var state = _workspace.state;
    if (state is WorkspaceLoading) {
      state = await _workspace.stream
          .firstWhere((s) => s is! WorkspaceLoading)
          .timeout(const Duration(seconds: 10), onTimeout: () => state);
    }
    // Signed out, or only an org admin: logging in comes first.
    if (state is! WorkspaceReady) return;
    final target = switch (message.orgId) {
      null => const PersonalWorkspace(),
      final orgId =>
        state.options
            .whereType<MemberWorkspace>()
            .where((w) => w.orgId == orgId)
            .firstOrNull,
    };
    // No longer in that company.
    if (target == null) return;
    if (target != state.current) await _workspace.choose(target);

    _router.go(AppRoutes.home);
    final path = destination(message.toNotification());
    final tab = path == null ? null : NotificationTab.values.asNameMap()[path];
    if (tab != null) {
      pendingTab.value = tab;
    } else {
      unawaited(_router.push(path ?? AppRoutes.notifications));
    }
  }

  /// Whether Android lets the app show notifications.
  Future<bool> allowed() => _messaging.allowed();

  /// The app's notification page in Android settings.
  Future<void> openSettings() => _messaging.openSettings();

  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    pendingTab.dispose();
    await _arrived.close();
  }
}
