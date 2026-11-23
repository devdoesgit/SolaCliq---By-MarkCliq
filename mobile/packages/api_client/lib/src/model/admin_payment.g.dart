// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_payment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminPaymentCWProxy {
  AdminPayment id(String id);

  AdminPayment customerId(String customerId);

  AdminPayment customerName(String customerName);

  AdminPayment customerReference(String customerReference);

  AdminPayment label(String label);

  AdminPayment amount(int amount);

  AdminPayment status(AdminPaymentStatus status);

  AdminPayment dueOn(String? dueOn);

  AdminPayment claimedAt(DateTime? claimedAt);

  AdminPayment claimedMethod(AdminPaymentClaimedMethodEnum? claimedMethod);

  AdminPayment paidOn(String? paidOn);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminPayment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminPayment(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminPayment call({
    String id,
    String customerId,
    String customerName,
    String customerReference,
    String label,
    int amount,
    AdminPaymentStatus status,
    String? dueOn,
    DateTime? claimedAt,
    AdminPaymentClaimedMethodEnum? claimedMethod,
    String? paidOn,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminPayment.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminPayment.copyWith.fieldName(...)`
class _$AdminPaymentCWProxyImpl implements _$AdminPaymentCWProxy {
  const _$AdminPaymentCWProxyImpl(this._value);

  final AdminPayment _value;

  @override
  AdminPayment id(String id) => this(id: id);

  @override
  AdminPayment customerId(String customerId) => this(customerId: customerId);

  @override
  AdminPayment customerName(String customerName) =>
      this(customerName: customerName);

  @override
  AdminPayment customerReference(String customerReference) =>
      this(customerReference: customerReference);

  @override
  AdminPayment label(String label) => this(label: label);

  @override
  AdminPayment amount(int amount) => this(amount: amount);

  @override
  AdminPayment status(AdminPaymentStatus status) => this(status: status);

  @override
  AdminPayment dueOn(String? dueOn) => this(dueOn: dueOn);

  @override
  AdminPayment claimedAt(DateTime? claimedAt) => this(claimedAt: claimedAt);

  @override
  AdminPayment claimedMethod(AdminPaymentClaimedMethodEnum? claimedMethod) =>
      this(claimedMethod: claimedMethod);

  @override
  AdminPayment paidOn(String? paidOn) => this(paidOn: paidOn);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminPayment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminPayment(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminPayment call({
    Object? id = const $CopyWithPlaceholder(),
    Object? customerId = const $CopyWithPlaceholder(),
    Object? customerName = const $CopyWithPlaceholder(),
    Object? customerReference = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? dueOn = const $CopyWithPlaceholder(),
    Object? claimedAt = const $CopyWithPlaceholder(),
    Object? claimedMethod = const $CopyWithPlaceholder(),
    Object? paidOn = const $CopyWithPlaceholder(),
  }) {
    return AdminPayment(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      customerId: customerId == const $CopyWithPlaceholder()
          ? _value.customerId
          // ignore: cast_nullable_to_non_nullable
          : customerId as String,
      customerName: customerName == const $CopyWithPlaceholder()
          ? _value.customerName
          // ignore: cast_nullable_to_non_nullable
          : customerName as String,
      customerReference: customerReference == const $CopyWithPlaceholder()
          ? _value.customerReference
          // ignore: cast_nullable_to_non_nullable
          : customerReference as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      amount: amount == const $CopyWithPlaceholder()
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AdminPaymentStatus,
      dueOn: dueOn == const $CopyWithPlaceholder()
          ? _value.dueOn
          // ignore: cast_nullable_to_non_nullable
          : dueOn as String?,
      claimedAt: claimedAt == const $CopyWithPlaceholder()
          ? _value.claimedAt
          // ignore: cast_nullable_to_non_nullable
          : claimedAt as DateTime?,
      claimedMethod: claimedMethod == const $CopyWithPlaceholder()
          ? _value.claimedMethod
          // ignore: cast_nullable_to_non_nullable
          : claimedMethod as AdminPaymentClaimedMethodEnum?,
      paidOn: paidOn == const $CopyWithPlaceholder()
          ? _value.paidOn
          // ignore: cast_nullable_to_non_nullable
          : paidOn as String?,
    );
  }
}

extension $AdminPaymentCopyWith on AdminPayment {
  /// Returns a callable class that can be used as follows: `instanceOfAdminPayment.copyWith(...)` or like so:`instanceOfAdminPayment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminPaymentCWProxy get copyWith => _$AdminPaymentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminPayment _$AdminPaymentFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminPayment',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'customer_id',
            'customer_name',
            'customer_reference',
            'label',
            'amount',
            'status',
          ],
        );
        final val = AdminPayment(
          id: $checkedConvert('id', (v) => v as String),
          customerId: $checkedConvert('customer_id', (v) => v as String),
          customerName: $checkedConvert('customer_name', (v) => v as String),
          customerReference: $checkedConvert(
            'customer_reference',
            (v) => v as String,
          ),
          label: $checkedConvert('label', (v) => v as String),
          amount: $checkedConvert('amount', (v) => (v as num).toInt()),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$AdminPaymentStatusEnumMap, v),
          ),
          dueOn: $checkedConvert('due_on', (v) => v as String?),
          claimedAt: $checkedConvert(
            'claimed_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          claimedMethod: $checkedConvert(
            'claimed_method',
            (v) =>
                $enumDecodeNullable(_$AdminPaymentClaimedMethodEnumEnumMap, v),
          ),
          paidOn: $checkedConvert('paid_on', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'customerId': 'customer_id',
        'customerName': 'customer_name',
        'customerReference': 'customer_reference',
        'dueOn': 'due_on',
        'claimedAt': 'claimed_at',
        'claimedMethod': 'claimed_method',
        'paidOn': 'paid_on',
      },
    );

Map<String, dynamic> _$AdminPaymentToJson(AdminPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customer_id': instance.customerId,
      'customer_name': instance.customerName,
      'customer_reference': instance.customerReference,
      'label': instance.label,
      'amount': instance.amount,
      'status': _$AdminPaymentStatusEnumMap[instance.status]!,
      'due_on': ?instance.dueOn,
      'claimed_at': ?instance.claimedAt?.toIso8601String(),
      'claimed_method':
          ?_$AdminPaymentClaimedMethodEnumEnumMap[instance.claimedMethod],
      'paid_on': ?instance.paidOn,
    };

const _$AdminPaymentStatusEnumMap = {
  AdminPaymentStatus.due: 'due',
  AdminPaymentStatus.claimed: 'claimed',
  AdminPaymentStatus.paid: 'paid',
  AdminPaymentStatus.later: 'later',
};

const _$AdminPaymentClaimedMethodEnumEnumMap = {
  AdminPaymentClaimedMethodEnum.upi: 'upi',
  AdminPaymentClaimedMethodEnum.bankTransfer: 'bank_transfer',
};
