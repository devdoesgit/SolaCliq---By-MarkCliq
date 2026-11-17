import 'package:api_client/api_client.dart' as api;
import 'package:equatable/equatable.dart';
import 'package:solacliq/app/data/api_call.dart';

enum NotificationKind {
  taskAssigned,
  taskApproved,
  taskReturned,
  taskCancelled,
  taskRescheduled,
  expenseApproved,
  expenseReturned,
  expensePaid,
  kycReturned,
  kycSubmitted,
  kycApproved,
  installStarted,
  commissionChanged,
  commissionPayable,
  commissionPaid,
  visitBooked,
  paymentDue,
  documentsVerified,
  quoteShared,
  guide,
}

class AppNotification extends Equatable {
  const new({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    required this.read,
    this.taskId,
    this.expenseId,
    this.customerId,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime at;
  final bool read;

  /// What it opens.
  final String? taskId;
  final String? expenseId;

  /// One of a Sales person's customers.
  final String? customerId;

  AppNotification markRead() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    at: at,
    read: true,
    taskId: taskId,
    expenseId: expenseId,
    customerId: customerId,
  );

  @override
  List<Object?> get props => [
    id,
    kind,
    title,
    body,
    at,
    read,
    taskId,
    expenseId,
    customerId,
  ];
}

/// The caller's notifications in one company.
class NotificationRepository {
  new(this._api);

  final api.NotificationsApi _api;

  /// In one company, or with no [orgId] the person's own (quotes,
  /// guides).
  Future<List<AppNotification>> list(String? orgId) async {
    final response = await apiCall(
      () => orgId == null
          ? _api.listMyNotifications()
          : _api.listNotifications(orgId: orgId),
    );
    return [
      for (final n in response.data!.items)
        AppNotification(
          id: n.id,
          kind: NotificationKind.values.byName(n.kind.name),
          title: n.title,
          body: n.body,
          at: n.at,
          read: n.read,
          taskId: n.taskId,
          expenseId: n.expenseId,
          customerId: n.customerId,
        ),
    ];
  }

  /// How many are unread, in one company or with no [orgId] the person's
  /// own: the bell's dot. Asks for one item; the count comes with it.
  Future<int> unreadCount(String? orgId) async {
    final response = await apiCall(
      () => orgId == null
          ? _api.listMyNotifications(limit: 1)
          : _api.listNotifications(orgId: orgId, limit: 1),
    );
    // No body: nothing to show, rather than a crash over a dot.
    return response.data?.unreadCount ?? 0;
  }

  /// Saves this phone's push token for the logged-in session (F12).
  Future<void> registerDevice(String token) => apiCall(
    () => _api.registerMyDevice(
      deviceRegistration: api.DeviceRegistration(
        token: token,
        platform: api.DeviceRegistrationPlatformEnum.android,
      ),
    ),
  );

  /// In one company, or with no [orgId] the person's own.
  Future<void> markAllRead(String? orgId) => apiCall(
    () => orgId == null
        ? _api.markMyNotificationsRead()
        : _api.markNotificationsRead(orgId: orgId),
  );
}
