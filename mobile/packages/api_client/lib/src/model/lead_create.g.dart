// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LeadCreateCWProxy {
  LeadCreate externalId(String? externalId);

  LeadCreate name(String name);

  LeadCreate phone(String phone);

  LeadCreate email(String? email);

  LeadCreate city(String? city);

  LeadCreate pinCode(String? pinCode);

  LeadCreate monthlyBill(String? monthlyBill);

  LeadCreate roofType(String? roofType);

  LeadCreate message(String? message);

  LeadCreate source_(String? source_);

  LeadCreate campaign(String? campaign);

  LeadCreate pageUrl(String? pageUrl);

  LeadCreate extra(Map<String, String>? extra);

  LeadCreate consent(bool consent);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadCreate call({
    String? externalId,
    String name,
    String phone,
    String? email,
    String? city,
    String? pinCode,
    String? monthlyBill,
    String? roofType,
    String? message,
    String? source_,
    String? campaign,
    String? pageUrl,
    Map<String, String>? extra,
    bool consent,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLeadCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLeadCreate.copyWith.fieldName(...)`
class _$LeadCreateCWProxyImpl implements _$LeadCreateCWProxy {
  const _$LeadCreateCWProxyImpl(this._value);

  final LeadCreate _value;

  @override
  LeadCreate externalId(String? externalId) => this(externalId: externalId);

  @override
  LeadCreate name(String name) => this(name: name);

  @override
  LeadCreate phone(String phone) => this(phone: phone);

  @override
  LeadCreate email(String? email) => this(email: email);

  @override
  LeadCreate city(String? city) => this(city: city);

  @override
  LeadCreate pinCode(String? pinCode) => this(pinCode: pinCode);

  @override
  LeadCreate monthlyBill(String? monthlyBill) => this(monthlyBill: monthlyBill);

  @override
  LeadCreate roofType(String? roofType) => this(roofType: roofType);

  @override
  LeadCreate message(String? message) => this(message: message);

  @override
  LeadCreate source_(String? source_) => this(source_: source_);

  @override
  LeadCreate campaign(String? campaign) => this(campaign: campaign);

  @override
  LeadCreate pageUrl(String? pageUrl) => this(pageUrl: pageUrl);

  @override
  LeadCreate extra(Map<String, String>? extra) => this(extra: extra);

  @override
  LeadCreate consent(bool consent) => this(consent: consent);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadCreate call({
    Object? externalId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? city = const $CopyWithPlaceholder(),
    Object? pinCode = const $CopyWithPlaceholder(),
    Object? monthlyBill = const $CopyWithPlaceholder(),
    Object? roofType = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? campaign = const $CopyWithPlaceholder(),
    Object? pageUrl = const $CopyWithPlaceholder(),
    Object? extra = const $CopyWithPlaceholder(),
    Object? consent = const $CopyWithPlaceholder(),
  }) {
    return LeadCreate(
      externalId: externalId == const $CopyWithPlaceholder()
          ? _value.externalId
          // ignore: cast_nullable_to_non_nullable
          : externalId as String?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      city: city == const $CopyWithPlaceholder()
          ? _value.city
          // ignore: cast_nullable_to_non_nullable
          : city as String?,
      pinCode: pinCode == const $CopyWithPlaceholder()
          ? _value.pinCode
          // ignore: cast_nullable_to_non_nullable
          : pinCode as String?,
      monthlyBill: monthlyBill == const $CopyWithPlaceholder()
          ? _value.monthlyBill
          // ignore: cast_nullable_to_non_nullable
          : monthlyBill as String?,
      roofType: roofType == const $CopyWithPlaceholder()
          ? _value.roofType
          // ignore: cast_nullable_to_non_nullable
          : roofType as String?,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String?,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as String?,
      campaign: campaign == const $CopyWithPlaceholder()
          ? _value.campaign
          // ignore: cast_nullable_to_non_nullable
          : campaign as String?,
      pageUrl: pageUrl == const $CopyWithPlaceholder()
          ? _value.pageUrl
          // ignore: cast_nullable_to_non_nullable
          : pageUrl as String?,
      extra: extra == const $CopyWithPlaceholder()
          ? _value.extra
          // ignore: cast_nullable_to_non_nullable
          : extra as Map<String, String>?,
      consent: consent == const $CopyWithPlaceholder()
          ? _value.consent
          // ignore: cast_nullable_to_non_nullable
          : consent as bool,
    );
  }
}

extension $LeadCreateCopyWith on LeadCreate {
  /// Returns a callable class that can be used as follows: `instanceOfLeadCreate.copyWith(...)` or like so:`instanceOfLeadCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LeadCreateCWProxy get copyWith => _$LeadCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeadCreate _$LeadCreateFromJson(Map<String, dynamic> json) => $checkedCreate(
  'LeadCreate',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['name', 'phone', 'consent']);
    final val = LeadCreate(
      externalId: $checkedConvert('external_id', (v) => v as String?),
      name: $checkedConvert('name', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String?),
      city: $checkedConvert('city', (v) => v as String?),
      pinCode: $checkedConvert('pin_code', (v) => v as String?),
      monthlyBill: $checkedConvert('monthly_bill', (v) => v as String?),
      roofType: $checkedConvert('roof_type', (v) => v as String?),
      message: $checkedConvert('message', (v) => v as String?),
      source_: $checkedConvert('source', (v) => v as String?),
      campaign: $checkedConvert('campaign', (v) => v as String?),
      pageUrl: $checkedConvert('page_url', (v) => v as String?),
      extra: $checkedConvert(
        'extra',
        (v) => (v as Map<String, dynamic>?)?.map(
          (k, e) => MapEntry(k, e as String),
        ),
      ),
      consent: $checkedConvert('consent', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'externalId': 'external_id',
    'pinCode': 'pin_code',
    'monthlyBill': 'monthly_bill',
    'roofType': 'roof_type',
    'source_': 'source',
    'pageUrl': 'page_url',
  },
);

Map<String, dynamic> _$LeadCreateToJson(LeadCreate instance) =>
    <String, dynamic>{
      'external_id': ?instance.externalId,
      'name': instance.name,
      'phone': instance.phone,
      'email': ?instance.email,
      'city': ?instance.city,
      'pin_code': ?instance.pinCode,
      'monthly_bill': ?instance.monthlyBill,
      'roof_type': ?instance.roofType,
      'message': ?instance.message,
      'source': ?instance.source_,
      'campaign': ?instance.campaign,
      'page_url': ?instance.pageUrl,
      'extra': ?instance.extra,
      'consent': instance.consent,
    };
