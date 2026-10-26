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
  inviteReceived,
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
  /// invites, guides).
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

  Future<void> markAllRead(String orgId) =>
      apiCall(() => _api.markNotificationsRead(orgId: orgId));
}
