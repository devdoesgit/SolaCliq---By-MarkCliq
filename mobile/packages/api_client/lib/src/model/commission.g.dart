// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commission.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CommissionCWProxy {
  Commission amount(int amount);

  Commission proposedAmount(int? proposedAmount);

  Commission status(CommissionStatus status);

  Commission adminNote(TaskNote? adminNote);

  Commission payableSince(String? payableSince);

  Commission paidOn(String? paidOn);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Commission(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Commission(...).copyWith(id: 12, name: "My name")
  /// ````
  Commission call({
    int amount,
    int? proposedAmount,
    CommissionStatus status,
    TaskNote? adminNote,
    String? payableSince,
    String? paidOn,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCommission.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCommission.copyWith.fieldName(...)`
class _$CommissionCWProxyImpl implements _$CommissionCWProxy {
  const _$CommissionCWProxyImpl(this._value);

  final Commission _value;

  @override
  Commission amount(int amount) => this(amount: amount);

  @override
  Commission proposedAmount(int? proposedAmount) =>
      this(proposedAmount: proposedAmount);

  @override
  Commission status(CommissionStatus status) => this(status: status);

  @override
  Commission adminNote(TaskNote? adminNote) => this(adminNote: adminNote);

  @override
  Commission payableSince(String? payableSince) =>
      this(payableSince: payableSince);

  @override
  Commission paidOn(String? paidOn) => this(paidOn: paidOn);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Commission(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Commission(...).copyWith(id: 12, name: "My name")
  /// ````
  Commission call({
    Object? amount = const $CopyWithPlaceholder(),
    Object? proposedAmount = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? adminNote = const $CopyWithPlaceholder(),
    Object? payableSince = const $CopyWithPlaceholder(),
    Object? paidOn = const $CopyWithPlaceholder(),
  }) {
    return Commission(
      amount: amount == const $CopyWithPlaceholder()
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
      proposedAmount: proposedAmount == const $CopyWithPlaceholder()
          ? _value.proposedAmount
          // ignore: cast_nullable_to_non_nullable
          : proposedAmount as int?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as CommissionStatus,
      adminNote: adminNote == const $CopyWithPlaceholder()
          ? _value.adminNote
          // ignore: cast_nullable_to_non_nullable
          : adminNote as TaskNote?,
      payableSince: payableSince == const $CopyWithPlaceholder()
          ? _value.payableSince
          // ignore: cast_nullable_to_non_nullable
          : payableSince as String?,
      paidOn: paidOn == const $CopyWithPlaceholder()
          ? _value.paidOn
          // ignore: cast_nullable_to_non_nullable
          : paidOn as String?,
    );
  }
}

extension $CommissionCopyWith on Commission {
  /// Returns a callable class that can be used as follows: `instanceOfCommission.copyWith(...)` or like so:`instanceOfCommission.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CommissionCWProxy get copyWith => _$CommissionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Commission _$CommissionFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Commission',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['amount', 'status']);
    final val = Commission(
      amount: $checkedConvert('amount', (v) => (v as num).toInt()),
      proposedAmount: $checkedConvert(
        'proposed_amount',
        (v) => (v as num?)?.toInt(),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$CommissionStatusEnumMap, v),
      ),
      adminNote: $checkedConvert(
        'admin_note',
        (v) => v == null ? null : TaskNote.fromJson(v as Map<String, dynamic>),
      ),
      payableSince: $checkedConvert('payable_since', (v) => v as String?),
      paidOn: $checkedConvert('paid_on', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'proposedAmount': 'proposed_amount',
    'adminNote': 'admin_note',
    'payableSince': 'payable_since',
    'paidOn': 'paid_on',
  },
);

Map<String, dynamic> _$CommissionToJson(Commission instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'proposed_amount': ?instance.proposedAmount,
      'status': _$CommissionStatusEnumMap[instance.status]!,
      'admin_note': ?instance.adminNote?.toJson(),
      'payable_since': ?instance.payableSince,
      'paid_on': ?instance.paidOn,
    };

const _$CommissionStatusEnumMap = {
  CommissionStatus.inReview: 'in_review',
  CommissionStatus.approved: 'approved',
  CommissionStatus.payable: 'payable',
  CommissionStatus.paid: 'paid',
};
