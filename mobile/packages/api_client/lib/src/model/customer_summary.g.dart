// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerSummaryCWProxy {
  CustomerSummary id(String id);

  CustomerSummary name(String name);

  CustomerSummary systemKw(num systemKw);

  CustomerSummary place(String place);

  CustomerSummary kycStatus(KycStatus kycStatus);

  CustomerSummary detail(String detail);

  CustomerSummary sentAt(DateTime sentAt);

  CustomerSummary commission(Commission? commission);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerSummary call({
    String id,
    String name,
    num systemKw,
    String place,
    KycStatus kycStatus,
    String detail,
    DateTime sentAt,
    Commission? commission,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCustomerSummary.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCustomerSummary.copyWith.fieldName(...)`
class _$CustomerSummaryCWProxyImpl implements _$CustomerSummaryCWProxy {
  const _$CustomerSummaryCWProxyImpl(this._value);

  final CustomerSummary _value;

  @override
  CustomerSummary id(String id) => this(id: id);

  @override
  CustomerSummary name(String name) => this(name: name);

  @override
  CustomerSummary systemKw(num systemKw) => this(systemKw: systemKw);

  @override
  CustomerSummary place(String place) => this(place: place);

  @override
  CustomerSummary kycStatus(KycStatus kycStatus) => this(kycStatus: kycStatus);

  @override
  CustomerSummary detail(String detail) => this(detail: detail);

  @override
  CustomerSummary sentAt(DateTime sentAt) => this(sentAt: sentAt);

  @override
  CustomerSummary commission(Commission? commission) =>
      this(commission: commission);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerSummary call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? systemKw = const $CopyWithPlaceholder(),
    Object? place = const $CopyWithPlaceholder(),
    Object? kycStatus = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? sentAt = const $CopyWithPlaceholder(),
    Object? commission = const $CopyWithPlaceholder(),
  }) {
    return CustomerSummary(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      systemKw: systemKw == const $CopyWithPlaceholder()
          ? _value.systemKw
          // ignore: cast_nullable_to_non_nullable
          : systemKw as num,
      place: place == const $CopyWithPlaceholder()
          ? _value.place
          // ignore: cast_nullable_to_non_nullable
          : place as String,
      kycStatus: kycStatus == const $CopyWithPlaceholder()
          ? _value.kycStatus
          // ignore: cast_nullable_to_non_nullable
          : kycStatus as KycStatus,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String,
      sentAt: sentAt == const $CopyWithPlaceholder()
          ? _value.sentAt
          // ignore: cast_nullable_to_non_nullable
          : sentAt as DateTime,
      commission: commission == const $CopyWithPlaceholder()
          ? _value.commission
          // ignore: cast_nullable_to_non_nullable
          : commission as Commission?,
    );
  }
}

extension $CustomerSummaryCopyWith on CustomerSummary {
  /// Returns a callable class that can be used as follows: `instanceOfCustomerSummary.copyWith(...)` or like so:`instanceOfCustomerSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerSummaryCWProxy get copyWith => _$CustomerSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerSummary _$CustomerSummaryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CustomerSummary',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'system_kw',
        'place',
        'kyc_status',
        'detail',
        'sent_at',
      ],
    );
    final val = CustomerSummary(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      systemKw: $checkedConvert('system_kw', (v) => v as num),
      place: $checkedConvert('place', (v) => v as String),
      kycStatus: $checkedConvert(
        'kyc_status',
        (v) => $enumDecode(_$KycStatusEnumMap, v),
      ),
      detail: $checkedConvert('detail', (v) => v as String),
      sentAt: $checkedConvert('sent_at', (v) => DateTime.parse(v as String)),
      commission: $checkedConvert(
        'commission',
        (v) =>
            v == null ? null : Commission.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'systemKw': 'system_kw',
    'kycStatus': 'kyc_status',
    'sentAt': 'sent_at',
  },
);

Map<String, dynamic> _$CustomerSummaryToJson(CustomerSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'system_kw': instance.systemKw,
      'place': instance.place,
      'kyc_status': _$KycStatusEnumMap[instance.kycStatus]!,
      'detail': instance.detail,
      'sent_at': instance.sentAt.toIso8601String(),
      'commission': ?instance.commission?.toJson(),
    };

const _$KycStatusEnumMap = {
  KycStatus.inReview: 'in_review',
  KycStatus.needsFix: 'needs_fix',
  KycStatus.approved: 'approved',
};
