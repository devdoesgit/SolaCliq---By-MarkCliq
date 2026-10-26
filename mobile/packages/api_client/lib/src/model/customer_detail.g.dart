// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_detail.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerDetailCWProxy {
  CustomerDetail id(String id);

  CustomerDetail name(String name);

  CustomerDetail phone(String phone);

  CustomerDetail systemKw(num systemKw);

  CustomerDetail place(String place);

  CustomerDetail kycStatus(KycStatus kycStatus);

  CustomerDetail detail(String detail);

  CustomerDetail sentAt(DateTime sentAt);

  CustomerDetail stage(CustomerDetailStage? stage);

  CustomerDetail returned(CustomerDetailReturned? returned);

  CustomerDetail documents(CustomerDetailDocuments? documents);

  CustomerDetail advance(CustomerDetailAdvance? advance);

  CustomerDetail commission(Commission? commission);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerDetail(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerDetail(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerDetail call({
    String id,
    String name,
    String phone,
    num systemKw,
    String place,
    KycStatus kycStatus,
    String detail,
    DateTime sentAt,
    CustomerDetailStage? stage,
    CustomerDetailReturned? returned,
    CustomerDetailDocuments? documents,
    CustomerDetailAdvance? advance,
    Commission? commission,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCustomerDetail.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCustomerDetail.copyWith.fieldName(...)`
class _$CustomerDetailCWProxyImpl implements _$CustomerDetailCWProxy {
  const _$CustomerDetailCWProxyImpl(this._value);

  final CustomerDetail _value;

  @override
  CustomerDetail id(String id) => this(id: id);

  @override
  CustomerDetail name(String name) => this(name: name);

  @override
  CustomerDetail phone(String phone) => this(phone: phone);

  @override
  CustomerDetail systemKw(num systemKw) => this(systemKw: systemKw);

  @override
  CustomerDetail place(String place) => this(place: place);

  @override
  CustomerDetail kycStatus(KycStatus kycStatus) => this(kycStatus: kycStatus);

  @override
  CustomerDetail detail(String detail) => this(detail: detail);

  @override
  CustomerDetail sentAt(DateTime sentAt) => this(sentAt: sentAt);

  @override
  CustomerDetail stage(CustomerDetailStage? stage) => this(stage: stage);

  @override
  CustomerDetail returned(CustomerDetailReturned? returned) =>
      this(returned: returned);

  @override
  CustomerDetail documents(CustomerDetailDocuments? documents) =>
      this(documents: documents);

  @override
  CustomerDetail advance(CustomerDetailAdvance? advance) =>
      this(advance: advance);

  @override
  CustomerDetail commission(Commission? commission) =>
      this(commission: commission);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerDetail(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerDetail(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerDetail call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? systemKw = const $CopyWithPlaceholder(),
    Object? place = const $CopyWithPlaceholder(),
    Object? kycStatus = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? sentAt = const $CopyWithPlaceholder(),
    Object? stage = const $CopyWithPlaceholder(),
    Object? returned = const $CopyWithPlaceholder(),
    Object? documents = const $CopyWithPlaceholder(),
    Object? advance = const $CopyWithPlaceholder(),
    Object? commission = const $CopyWithPlaceholder(),
  }) {
    return CustomerDetail(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
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
      stage: stage == const $CopyWithPlaceholder()
          ? _value.stage
          // ignore: cast_nullable_to_non_nullable
          : stage as CustomerDetailStage?,
      returned: returned == const $CopyWithPlaceholder()
          ? _value.returned
          // ignore: cast_nullable_to_non_nullable
          : returned as CustomerDetailReturned?,
      documents: documents == const $CopyWithPlaceholder()
          ? _value.documents
          // ignore: cast_nullable_to_non_nullable
          : documents as CustomerDetailDocuments?,
      advance: advance == const $CopyWithPlaceholder()
          ? _value.advance
          // ignore: cast_nullable_to_non_nullable
          : advance as CustomerDetailAdvance?,
      commission: commission == const $CopyWithPlaceholder()
          ? _value.commission
          // ignore: cast_nullable_to_non_nullable
          : commission as Commission?,
    );
  }
}

extension $CustomerDetailCopyWith on CustomerDetail {
  /// Returns a callable class that can be used as follows: `instanceOfCustomerDetail.copyWith(...)` or like so:`instanceOfCustomerDetail.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerDetailCWProxy get copyWith => _$CustomerDetailCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerDetail _$CustomerDetailFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CustomerDetail',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'phone',
        'system_kw',
        'place',
        'kyc_status',
        'detail',
        'sent_at',
      ],
    );
    final val = CustomerDetail(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String),
      systemKw: $checkedConvert('system_kw', (v) => v as num),
      place: $checkedConvert('place', (v) => v as String),
      kycStatus: $checkedConvert(
        'kyc_status',
        (v) => $enumDecode(_$KycStatusEnumMap, v),
      ),
      detail: $checkedConvert('detail', (v) => v as String),
      sentAt: $checkedConvert('sent_at', (v) => DateTime.parse(v as String)),
      stage: $checkedConvert(
        'stage',
        (v) => v == null
            ? null
            : CustomerDetailStage.fromJson(v as Map<String, dynamic>),
      ),
      returned: $checkedConvert(
        'returned',
        (v) => v == null
            ? null
            : CustomerDetailReturned.fromJson(v as Map<String, dynamic>),
      ),
      documents: $checkedConvert(
        'documents',
        (v) => v == null
            ? null
            : CustomerDetailDocuments.fromJson(v as Map<String, dynamic>),
      ),
      advance: $checkedConvert(
        'advance',
        (v) => v == null
            ? null
            : CustomerDetailAdvance.fromJson(v as Map<String, dynamic>),
      ),
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

Map<String, dynamic> _$CustomerDetailToJson(CustomerDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'system_kw': instance.systemKw,
      'place': instance.place,
      'kyc_status': _$KycStatusEnumMap[instance.kycStatus]!,
      'detail': instance.detail,
      'sent_at': instance.sentAt.toIso8601String(),
      'stage': ?instance.stage?.toJson(),
      'returned': ?instance.returned?.toJson(),
      'documents': ?instance.documents?.toJson(),
      'advance': ?instance.advance?.toJson(),
      'commission': ?instance.commission?.toJson(),
    };

const _$KycStatusEnumMap = {
  KycStatus.inReview: 'in_review',
  KycStatus.needsFix: 'needs_fix',
  KycStatus.approved: 'approved',
};
