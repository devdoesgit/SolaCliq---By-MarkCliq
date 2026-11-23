// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_commission.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminCommissionCWProxy {
  AdminCommission customerId(String customerId);

  AdminCommission customerName(String customerName);

  AdminCommission customerReference(String customerReference);

  AdminCommission agentName(String? agentName);

  AdminCommission amount(int amount);

  AdminCommission proposedAmount(int? proposedAmount);

  AdminCommission note(String? note);

  AdminCommission adminNote(String? adminNote);

  AdminCommission status(CommissionStatus status);

  AdminCommission advancePaid(bool advancePaid);

  AdminCommission payableSince(String? payableSince);

  AdminCommission paidOn(String? paidOn);

  AdminCommission payoutLast4(String? payoutLast4);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminCommission(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminCommission(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminCommission call({
    String customerId,
    String customerName,
    String customerReference,
    String? agentName,
    int amount,
    int? proposedAmount,
    String? note,
    String? adminNote,
    CommissionStatus status,
    bool advancePaid,
    String? payableSince,
    String? paidOn,
    String? payoutLast4,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminCommission.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminCommission.copyWith.fieldName(...)`
class _$AdminCommissionCWProxyImpl implements _$AdminCommissionCWProxy {
  const _$AdminCommissionCWProxyImpl(this._value);

  final AdminCommission _value;

  @override
  AdminCommission customerId(String customerId) => this(customerId: customerId);

  @override
  AdminCommission customerName(String customerName) =>
      this(customerName: customerName);

  @override
  AdminCommission customerReference(String customerReference) =>
      this(customerReference: customerReference);

  @override
  AdminCommission agentName(String? agentName) => this(agentName: agentName);

  @override
  AdminCommission amount(int amount) => this(amount: amount);

  @override
  AdminCommission proposedAmount(int? proposedAmount) =>
      this(proposedAmount: proposedAmount);

  @override
  AdminCommission note(String? note) => this(note: note);

  @override
  AdminCommission adminNote(String? adminNote) => this(adminNote: adminNote);

  @override
  AdminCommission status(CommissionStatus status) => this(status: status);

  @override
  AdminCommission advancePaid(bool advancePaid) =>
      this(advancePaid: advancePaid);

  @override
  AdminCommission payableSince(String? payableSince) =>
      this(payableSince: payableSince);

  @override
  AdminCommission paidOn(String? paidOn) => this(paidOn: paidOn);

  @override
  AdminCommission payoutLast4(String? payoutLast4) =>
      this(payoutLast4: payoutLast4);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminCommission(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminCommission(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminCommission call({
    Object? customerId = const $CopyWithPlaceholder(),
    Object? customerName = const $CopyWithPlaceholder(),
    Object? customerReference = const $CopyWithPlaceholder(),
    Object? agentName = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? proposedAmount = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? adminNote = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? advancePaid = const $CopyWithPlaceholder(),
    Object? payableSince = const $CopyWithPlaceholder(),
    Object? paidOn = const $CopyWithPlaceholder(),
    Object? payoutLast4 = const $CopyWithPlaceholder(),
  }) {
    return AdminCommission(
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
      agentName: agentName == const $CopyWithPlaceholder()
          ? _value.agentName
          // ignore: cast_nullable_to_non_nullable
          : agentName as String?,
      amount: amount == const $CopyWithPlaceholder()
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
      proposedAmount: proposedAmount == const $CopyWithPlaceholder()
          ? _value.proposedAmount
          // ignore: cast_nullable_to_non_nullable
          : proposedAmount as int?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      adminNote: adminNote == const $CopyWithPlaceholder()
          ? _value.adminNote
          // ignore: cast_nullable_to_non_nullable
          : adminNote as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as CommissionStatus,
      advancePaid: advancePaid == const $CopyWithPlaceholder()
          ? _value.advancePaid
          // ignore: cast_nullable_to_non_nullable
          : advancePaid as bool,
      payableSince: payableSince == const $CopyWithPlaceholder()
          ? _value.payableSince
          // ignore: cast_nullable_to_non_nullable
          : payableSince as String?,
      paidOn: paidOn == const $CopyWithPlaceholder()
          ? _value.paidOn
          // ignore: cast_nullable_to_non_nullable
          : paidOn as String?,
      payoutLast4: payoutLast4 == const $CopyWithPlaceholder()
          ? _value.payoutLast4
          // ignore: cast_nullable_to_non_nullable
          : payoutLast4 as String?,
    );
  }
}

extension $AdminCommissionCopyWith on AdminCommission {
  /// Returns a callable class that can be used as follows: `instanceOfAdminCommission.copyWith(...)` or like so:`instanceOfAdminCommission.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminCommissionCWProxy get copyWith => _$AdminCommissionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCommission _$AdminCommissionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminCommission',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'customer_id',
            'customer_name',
            'customer_reference',
            'amount',
            'status',
            'advance_paid',
          ],
        );
        final val = AdminCommission(
          customerId: $checkedConvert('customer_id', (v) => v as String),
          customerName: $checkedConvert('customer_name', (v) => v as String),
          customerReference: $checkedConvert(
            'customer_reference',
            (v) => v as String,
          ),
          agentName: $checkedConvert('agent_name', (v) => v as String?),
          amount: $checkedConvert('amount', (v) => (v as num).toInt()),
          proposedAmount: $checkedConvert(
            'proposed_amount',
            (v) => (v as num?)?.toInt(),
          ),
          note: $checkedConvert('note', (v) => v as String?),
          adminNote: $checkedConvert('admin_note', (v) => v as String?),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$CommissionStatusEnumMap, v),
          ),
          advancePaid: $checkedConvert('advance_paid', (v) => v as bool),
          payableSince: $checkedConvert('payable_since', (v) => v as String?),
          paidOn: $checkedConvert('paid_on', (v) => v as String?),
          payoutLast4: $checkedConvert('payout_last4', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'customerId': 'customer_id',
        'customerName': 'customer_name',
        'customerReference': 'customer_reference',
        'agentName': 'agent_name',
        'proposedAmount': 'proposed_amount',
        'adminNote': 'admin_note',
        'advancePaid': 'advance_paid',
        'payableSince': 'payable_since',
        'paidOn': 'paid_on',
        'payoutLast4': 'payout_last4',
      },
    );

Map<String, dynamic> _$AdminCommissionToJson(AdminCommission instance) =>
    <String, dynamic>{
      'customer_id': instance.customerId,
      'customer_name': instance.customerName,
      'customer_reference': instance.customerReference,
      'agent_name': ?instance.agentName,
      'amount': instance.amount,
      'proposed_amount': ?instance.proposedAmount,
      'note': ?instance.note,
      'admin_note': ?instance.adminNote,
      'status': _$CommissionStatusEnumMap[instance.status]!,
      'advance_paid': instance.advancePaid,
      'payable_since': ?instance.payableSince,
      'paid_on': ?instance.paidOn,
      'payout_last4': ?instance.payoutLast4,
    };

const _$CommissionStatusEnumMap = {
  CommissionStatus.inReview: 'in_review',
  CommissionStatus.approved: 'approved',
  CommissionStatus.payable: 'payable',
  CommissionStatus.paid: 'paid',
};
