// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_customer_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminCustomerSummaryCWProxy {
  AdminCustomerSummary id(String id);

  AdminCustomerSummary reference(String reference);

  AdminCustomerSummary name(String name);

  AdminCustomerSummary phone(String? phone);

  AdminCustomerSummary place(String place);

  AdminCustomerSummary systemKw(num? systemKw);

  AdminCustomerSummary kycStatus(KycStatus kycStatus);

  AdminCustomerSummary stage(AdminStage? stage);

  AdminCustomerSummary agentName(String? agentName);

  AdminCustomerSummary advanceStatus(AdminPaymentStatus? advanceStatus);

  AdminCustomerSummary commissionAmount(int? commissionAmount);

  AdminCustomerSummary createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminCustomerSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminCustomerSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminCustomerSummary call({
    String id,
    String reference,
    String name,
    String? phone,
    String place,
    num? systemKw,
    KycStatus kycStatus,
    AdminStage? stage,
    String? agentName,
    AdminPaymentStatus? advanceStatus,
    int? commissionAmount,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminCustomerSummary.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminCustomerSummary.copyWith.fieldName(...)`
class _$AdminCustomerSummaryCWProxyImpl
    implements _$AdminCustomerSummaryCWProxy {
  const _$AdminCustomerSummaryCWProxyImpl(this._value);

  final AdminCustomerSummary _value;

  @override
  AdminCustomerSummary id(String id) => this(id: id);

  @override
  AdminCustomerSummary reference(String reference) =>
      this(reference: reference);

  @override
  AdminCustomerSummary name(String name) => this(name: name);

  @override
  AdminCustomerSummary phone(String? phone) => this(phone: phone);

  @override
  AdminCustomerSummary place(String place) => this(place: place);

  @override
  AdminCustomerSummary systemKw(num? systemKw) => this(systemKw: systemKw);

  @override
  AdminCustomerSummary kycStatus(KycStatus kycStatus) =>
      this(kycStatus: kycStatus);

  @override
  AdminCustomerSummary stage(AdminStage? stage) => this(stage: stage);

  @override
  AdminCustomerSummary agentName(String? agentName) =>
      this(agentName: agentName);

  @override
  AdminCustomerSummary advanceStatus(AdminPaymentStatus? advanceStatus) =>
      this(advanceStatus: advanceStatus);

  @override
  AdminCustomerSummary commissionAmount(int? commissionAmount) =>
      this(commissionAmount: commissionAmount);

  @override
  AdminCustomerSummary createdAt(DateTime createdAt) =>
      this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminCustomerSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminCustomerSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminCustomerSummary call({
    Object? id = const $CopyWithPlaceholder(),
    Object? reference = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? place = const $CopyWithPlaceholder(),
    Object? systemKw = const $CopyWithPlaceholder(),
    Object? kycStatus = const $CopyWithPlaceholder(),
    Object? stage = const $CopyWithPlaceholder(),
    Object? agentName = const $CopyWithPlaceholder(),
    Object? advanceStatus = const $CopyWithPlaceholder(),
    Object? commissionAmount = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return AdminCustomerSummary(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      reference: reference == const $CopyWithPlaceholder()
          ? _value.reference
          // ignore: cast_nullable_to_non_nullable
          : reference as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
      place: place == const $CopyWithPlaceholder()
          ? _value.place
          // ignore: cast_nullable_to_non_nullable
          : place as String,
      systemKw: systemKw == const $CopyWithPlaceholder()
          ? _value.systemKw
          // ignore: cast_nullable_to_non_nullable
          : systemKw as num?,
      kycStatus: kycStatus == const $CopyWithPlaceholder()
          ? _value.kycStatus
          // ignore: cast_nullable_to_non_nullable
          : kycStatus as KycStatus,
      stage: stage == const $CopyWithPlaceholder()
          ? _value.stage
          // ignore: cast_nullable_to_non_nullable
          : stage as AdminStage?,
      agentName: agentName == const $CopyWithPlaceholder()
          ? _value.agentName
          // ignore: cast_nullable_to_non_nullable
          : agentName as String?,
      advanceStatus: advanceStatus == const $CopyWithPlaceholder()
          ? _value.advanceStatus
          // ignore: cast_nullable_to_non_nullable
          : advanceStatus as AdminPaymentStatus?,
      commissionAmount: commissionAmount == const $CopyWithPlaceholder()
          ? _value.commissionAmount
          // ignore: cast_nullable_to_non_nullable
          : commissionAmount as int?,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $AdminCustomerSummaryCopyWith on AdminCustomerSummary {
  /// Returns a callable class that can be used as follows: `instanceOfAdminCustomerSummary.copyWith(...)` or like so:`instanceOfAdminCustomerSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminCustomerSummaryCWProxy get copyWith =>
      _$AdminCustomerSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCustomerSummary _$AdminCustomerSummaryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AdminCustomerSummary',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'reference',
        'name',
        'place',
        'kyc_status',
        'created_at',
      ],
    );
    final val = AdminCustomerSummary(
      id: $checkedConvert('id', (v) => v as String),
      reference: $checkedConvert('reference', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String?),
      place: $checkedConvert('place', (v) => v as String),
      systemKw: $checkedConvert('system_kw', (v) => v as num?),
      kycStatus: $checkedConvert(
        'kyc_status',
        (v) => $enumDecode(_$KycStatusEnumMap, v),
      ),
      stage: $checkedConvert(
        'stage',
        (v) =>
            v == null ? null : AdminStage.fromJson(v as Map<String, dynamic>),
      ),
      agentName: $checkedConvert('agent_name', (v) => v as String?),
      advanceStatus: $checkedConvert(
        'advance_status',
        (v) => $enumDecodeNullable(_$AdminPaymentStatusEnumMap, v),
      ),
      commissionAmount: $checkedConvert(
        'commission_amount',
        (v) => (v as num?)?.toInt(),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'systemKw': 'system_kw',
    'kycStatus': 'kyc_status',
    'agentName': 'agent_name',
    'advanceStatus': 'advance_status',
    'commissionAmount': 'commission_amount',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$AdminCustomerSummaryToJson(
  AdminCustomerSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'reference': instance.reference,
  'name': instance.name,
  'phone': ?instance.phone,
  'place': instance.place,
  'system_kw': ?instance.systemKw,
  'kyc_status': _$KycStatusEnumMap[instance.kycStatus]!,
  'stage': ?instance.stage?.toJson(),
  'agent_name': ?instance.agentName,
  'advance_status': ?_$AdminPaymentStatusEnumMap[instance.advanceStatus],
  'commission_amount': ?instance.commissionAmount,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$KycStatusEnumMap = {
  KycStatus.inReview: 'in_review',
  KycStatus.needsFix: 'needs_fix',
  KycStatus.approved: 'approved',
  KycStatus.rejected: 'rejected',
};

const _$AdminPaymentStatusEnumMap = {
  AdminPaymentStatus.due: 'due',
  AdminPaymentStatus.claimed: 'claimed',
  AdminPaymentStatus.paid: 'paid',
  AdminPaymentStatus.later: 'later',
};
