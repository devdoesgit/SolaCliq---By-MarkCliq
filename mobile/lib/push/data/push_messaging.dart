import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:solacliq/notifications/data/notification_repository.dart';

/// What a push carries (F12): the notification's kind and the ids that say
/// what it opens. Its title and body are shown by Android itself.
class PushMessage extends Equatable {
  const new({
    required this.kind,
    this.notificationId,
    this.orgId,
    this.taskId,
    this.expenseId,
    this.customerId,
  });

  /// From the push's `data`; null when it isn't one of ours.
  static PushMessage? fromData(Map<String, dynamic> data) {
    final kind = NotificationKind.values.asNameMap()[_camel(data['kind'])];
    if (kind == null) return null;
    String? id(String key) => switch (data[key]) {
      final String v when v.isNotEmpty => v,
      _ => null,
    };
    return PushMessage(
      kind: kind,
      notificationId: id('notification_id'),
      orgId: id('org_id'),
      taskId: id('task_id'),
      expenseId: id('expense_id'),
      customerId: id('customer_id'),
    );
  }

  final NotificationKind kind;
  final String? notificationId;

  /// The company it belongs to; null for the Personal workspace.
  final String? orgId;
  final String? taskId;
  final String? expenseId;
  final String? customerId;

  /// As a list item, to open it the way the notifications list does.
  AppNotification toNotification() => AppNotification(
    id: notificationId ?? '',
    kind: kind,
    title: '',
    body: '',
    at: DateTime.now(),
    read: true,
    taskId: taskId,
    expenseId: expenseId,
    customerId: customerId,
  );

  @override
  List<Object?> get props => [
    kind,
    notificationId,
    orgId,
    taskId,
    expenseId,
    customerId,
  ];
}

/// `task_assigned` → `taskAssigned`.
String _camel(Object? snake) {
  if (snake is! String) return '';
  final parts = snake.split('_');
  return parts.first +
      parts
          .skip(1)
          .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
          .join();
}

/// The phone's side of push: Firebase in the app, nothing in tests.
abstract interface class PushMessaging {
  /// Gets ready; false when this phone can't receive pushes.
  Future<bool> start();

  /// This install's token, or null when there's none.
  Future<String?> token();

  /// A new token from Firebase, to send to the server again.
  Stream<String> get tokenRefreshes;

  /// Asks Android for permission to show notifications (13+). True when
  /// allowed.
  Future<bool> requestPermission();

  /// Whether notifications are allowed now.
  Future<bool> allowed();

  /// The push that opened the app from closed, if one did.
  Future<PushMessage?> initialTap();

  /// Pushes tapped while the app was in the background.
  Stream<PushMessage> get taps;

  /// Pushes that arrived with the app open (no banner is shown).
  Stream<PushMessage> get received;

  /// The app's notification page in Android settings.
  Future<void> openSettings();
}

/// No push: tests, and phones without Google Play services.
class NoPushMessaging implements PushMessaging {
  const new();

  @override
  Future<bool> start() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> allowed() async => true;

  @override
  Future<PushMessage?> initialTap() async => null;

  @override
  Stream<PushMessage> get taps => const Stream.empty();

  @override
  Stream<PushMessage> get received => const Stream.empty();

  @override
  Future<void> openSettings() async {}
}

/// Firebase Cloud Messaging. The app's config comes from
/// `android/app/google-services.json`.
class FirebasePushMessaging implements PushMessaging {
  static const _channel = MethodChannel('solacliq/push');

  bool _ready = false;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  @override
  Future<bool> start() async {
    try {
      await Firebase.initializeApp();
      _ready = true;
    } on Exception catch (e) {
      log('Push unavailable: $e');
    }
    return _ready;
  }

  @override
  Future<String?> token() async {
    if (!_ready) return null;
    try {
      // Registration tokens, which the server's FCM HTTP v1 sends to.
      // firebase_messaging 17 deprecates them for installation ids
      // (register/onRegistered); moving means changing both sides.
      // ignore: deprecated_member_use
      return await _fcm.getToken();
    } on Exception catch (e) {
      // No Google Play services, or no network yet: try on the next start.
      log('No push token: $e');
      return null;
    }
  }

  @override
  Stream<String> get tokenRefreshes =>
      // See [token].
      // ignore: deprecated_member_use
      _ready ? _fcm.onTokenRefresh : const Stream.empty();

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final settings = await _fcm.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<bool> allowed() async {
    if (!_ready) return true;
    final settings = await _fcm.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<PushMessage?> initialTap() async {
    if (!_ready) return null;
    final message = await _fcm.getInitialMessage();
    return message == null ? null : PushMessage.fromData(message.data);
  }

  @override
  Stream<PushMessage> get taps => _ready
      ? FirebaseMessaging.onMessageOpenedApp
            .map((m) => PushMessage.fromData(m.data))
            .where((m) => m != null)
            .cast<PushMessage>()
      : const Stream.empty();

  @override
  Stream<PushMessage> get received => _ready
      ? FirebaseMessaging.onMessage
            .map((m) => PushMessage.fromData(m.data))
            .where((m) => m != null)
            .cast<PushMessage>()
      : const Stream.empty();

  @override
  Future<void> openSettings() =>
      _channel.invokeMethod<void>('openNotificationSettings');
}
