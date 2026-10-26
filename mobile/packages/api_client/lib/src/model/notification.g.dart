// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NotificationCWProxy {
  Notification id(String id);

  Notification kind(NotificationKindEnum kind);

  Notification title(String title);

  Notification body(String body);

  Notification at(DateTime at);

  Notification read(bool read);

  Notification taskId(String? taskId);

  Notification expenseId(String? expenseId);

  Notification customerId(String? customerId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Notification(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Notification(...).copyWith(id: 12, name: "My name")
  /// ````
  Notification call({
    String id,
    NotificationKindEnum kind,
    String title,
    String body,
    DateTime at,
    bool read,
    String? taskId,
    String? expenseId,
    String? customerId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNotification.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNotification.copyWith.fieldName(...)`
class _$NotificationCWProxyImpl implements _$NotificationCWProxy {
  const _$NotificationCWProxyImpl(this._value);

  final Notification _value;

  @override
  Notification id(String id) => this(id: id);

  @override
  Notification kind(NotificationKindEnum kind) => this(kind: kind);

  @override
  Notification title(String title) => this(title: title);

  @override
  Notification body(String body) => this(body: body);

  @override
  Notification at(DateTime at) => this(at: at);

  @override
  Notification read(bool read) => this(read: read);

  @override
  Notification taskId(String? taskId) => this(taskId: taskId);

  @override
  Notification expenseId(String? expenseId) => this(expenseId: expenseId);

  @override
  Notification customerId(String? customerId) => this(customerId: customerId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Notification(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Notification(...).copyWith(id: 12, name: "My name")
  /// ````
  Notification call({
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? read = const $CopyWithPlaceholder(),
    Object? taskId = const $CopyWithPlaceholder(),
    Object? expenseId = const $CopyWithPlaceholder(),
    Object? customerId = const $CopyWithPlaceholder(),
  }) {
    return Notification(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as NotificationKindEnum,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      body: body == const $CopyWithPlaceholder()
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as String,
      at: at == const $CopyWithPlaceholder()
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
      read: read == const $CopyWithPlaceholder()
          ? _value.read
          // ignore: cast_nullable_to_non_nullable
          : read as bool,
      taskId: taskId == const $CopyWithPlaceholder()
          ? _value.taskId
          // ignore: cast_nullable_to_non_nullable
          : taskId as String?,
      expenseId: expenseId == const $CopyWithPlaceholder()
          ? _value.expenseId
          // ignore: cast_nullable_to_non_nullable
          : expenseId as String?,
      customerId: customerId == const $CopyWithPlaceholder()
          ? _value.customerId
          // ignore: cast_nullable_to_non_nullable
          : customerId as String?,
    );
  }
}

extension $NotificationCopyWith on Notification {
  /// Returns a callable class that can be used as follows: `instanceOfNotification.copyWith(...)` or like so:`instanceOfNotification.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NotificationCWProxy get copyWith => _$NotificationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'Notification',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'kind', 'title', 'body', 'at', 'read'],
        );
        final val = Notification(
          id: $checkedConvert('id', (v) => v as String),
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecode(_$NotificationKindEnumEnumMap, v),
          ),
          title: $checkedConvert('title', (v) => v as String),
          body: $checkedConvert('body', (v) => v as String),
          at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
          read: $checkedConvert('read', (v) => v as bool),
          taskId: $checkedConvert('task_id', (v) => v as String?),
          expenseId: $checkedConvert('expense_id', (v) => v as String?),
          customerId: $checkedConvert('customer_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'taskId': 'task_id',
        'expenseId': 'expense_id',
        'customerId': 'customer_id',
      },
    );

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$NotificationKindEnumEnumMap[instance.kind]!,
      'title': instance.title,
      'body': instance.body,
      'at': instance.at.toIso8601String(),
      'read': instance.read,
      'task_id': ?instance.taskId,
      'expense_id': ?instance.expenseId,
      'customer_id': ?instance.customerId,
    };

const _$NotificationKindEnumEnumMap = {
  NotificationKindEnum.taskAssigned: 'task_assigned',
  NotificationKindEnum.taskApproved: 'task_approved',
  NotificationKindEnum.taskReturned: 'task_returned',
  NotificationKindEnum.taskCancelled: 'task_cancelled',
  NotificationKindEnum.taskRescheduled: 'task_rescheduled',
  NotificationKindEnum.expenseApproved: 'expense_approved',
  NotificationKindEnum.expenseReturned: 'expense_returned',
  NotificationKindEnum.expensePaid: 'expense_paid',
  NotificationKindEnum.kycReturned: 'kyc_returned',
  NotificationKindEnum.kycSubmitted: 'kyc_submitted',
  NotificationKindEnum.kycApproved: 'kyc_approved',
  NotificationKindEnum.installStarted: 'install_started',
  NotificationKindEnum.commissionChanged: 'commission_changed',
  NotificationKindEnum.commissionPayable: 'commission_payable',
  NotificationKindEnum.commissionPaid: 'commission_paid',
  NotificationKindEnum.visitBooked: 'visit_booked',
  NotificationKindEnum.paymentDue: 'payment_due',
  NotificationKindEnum.documentsVerified: 'documents_verified',
  NotificationKindEnum.quoteShared: 'quote_shared',
  NotificationKindEnum.inviteReceived: 'invite_received',
  NotificationKindEnum.guide: 'guide',
};
