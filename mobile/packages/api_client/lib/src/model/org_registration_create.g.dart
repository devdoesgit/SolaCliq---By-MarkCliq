// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'org_registration_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OrgRegistrationCreateCWProxy {
  OrgRegistrationCreate legalName(String legalName);

  OrgRegistrationCreate tradeName(String? tradeName);

  OrgRegistrationCreate businessType(BusinessType businessType);

  OrgRegistrationCreate gstin(String gstin);

  OrgRegistrationCreate addressLine1(String addressLine1);

  OrgRegistrationCreate addressLine2(String? addressLine2);

  OrgRegistrationCreate city(String city);

  OrgRegistrationCreate pinCode(String pinCode);

  OrgRegistrationCreate ownerName(String ownerName);

  OrgRegistrationCreate email(String email);

  OrgRegistrationCreate phone(String phone);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OrgRegistrationCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OrgRegistrationCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  OrgRegistrationCreate call({
    String legalName,
    String? tradeName,
    BusinessType businessType,
    String gstin,
    String addressLine1,
    String? addressLine2,
    String city,
    String pinCode,
    String ownerName,
    String email,
    String phone,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfOrgRegistrationCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfOrgRegistrationCreate.copyWith.fieldName(...)`
class _$OrgRegistrationCreateCWProxyImpl
    implements _$OrgRegistrationCreateCWProxy {
  const _$OrgRegistrationCreateCWProxyImpl(this._value);

  final OrgRegistrationCreate _value;

  @override
  OrgRegistrationCreate legalName(String legalName) =>
      this(legalName: legalName);

  @override
  OrgRegistrationCreate tradeName(String? tradeName) =>
      this(tradeName: tradeName);

  @override
  OrgRegistrationCreate businessType(BusinessType businessType) =>
      this(businessType: businessType);

  @override
  OrgRegistrationCreate gstin(String gstin) => this(gstin: gstin);

  @override
  OrgRegistrationCreate addressLine1(String addressLine1) =>
      this(addressLine1: addressLine1);

  @override
  OrgRegistrationCreate addressLine2(String? addressLine2) =>
      this(addressLine2: addressLine2);

  @override
  OrgRegistrationCreate city(String city) => this(city: city);

  @override
  OrgRegistrationCreate pinCode(String pinCode) => this(pinCode: pinCode);

  @override
  OrgRegistrationCreate ownerName(String ownerName) =>
      this(ownerName: ownerName);

  @override
  OrgRegistrationCreate email(String email) => this(email: email);

  @override
  OrgRegistrationCreate phone(String phone) => this(phone: phone);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OrgRegistrationCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OrgRegistrationCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  OrgRegistrationCreate call({
    Object? legalName = const $CopyWithPlaceholder(),
    Object? tradeName = const $CopyWithPlaceholder(),
    Object? businessType = const $CopyWithPlaceholder(),
    Object? gstin = const $CopyWithPlaceholder(),
    Object? addressLine1 = const $CopyWithPlaceholder(),
    Object? addressLine2 = const $CopyWithPlaceholder(),
    Object? city = const $CopyWithPlaceholder(),
    Object? pinCode = const $CopyWithPlaceholder(),
    Object? ownerName = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
  }) {
    return OrgRegistrationCreate(
      legalName: legalName == const $CopyWithPlaceholder()
          ? _value.legalName
          // ignore: cast_nullable_to_non_nullable
          : legalName as String,
      tradeName: tradeName == const $CopyWithPlaceholder()
          ? _value.tradeName
          // ignore: cast_nullable_to_non_nullable
          : tradeName as String?,
      businessType: businessType == const $CopyWithPlaceholder()
          ? _value.businessType
          // ignore: cast_nullable_to_non_nullable
          : businessType as BusinessType,
      gstin: gstin == const $CopyWithPlaceholder()
          ? _value.gstin
          // ignore: cast_nullable_to_non_nullable
          : gstin as String,
      addressLine1: addressLine1 == const $CopyWithPlaceholder()
          ? _value.addressLine1
          // ignore: cast_nullable_to_non_nullable
          : addressLine1 as String,
      addressLine2: addressLine2 == const $CopyWithPlaceholder()
          ? _value.addressLine2
          // ignore: cast_nullable_to_non_nullable
          : addressLine2 as String?,
      city: city == const $CopyWithPlaceholder()
          ? _value.city
          // ignore: cast_nullable_to_non_nullable
          : city as String,
      pinCode: pinCode == const $CopyWithPlaceholder()
          ? _value.pinCode
          // ignore: cast_nullable_to_non_nullable
          : pinCode as String,
      ownerName: ownerName == const $CopyWithPlaceholder()
          ? _value.ownerName
          // ignore: cast_nullable_to_non_nullable
          : ownerName as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
    );
  }
}

extension $OrgRegistrationCreateCopyWith on OrgRegistrationCreate {
  /// Returns a callable class that can be used as follows: `instanceOfOrgRegistrationCreate.copyWith(...)` or like so:`instanceOfOrgRegistrationCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OrgRegistrationCreateCWProxy get copyWith =>
      _$OrgRegistrationCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrgRegistrationCreate _$OrgRegistrationCreateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'OrgRegistrationCreate',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'legal_name',
        'business_type',
        'gstin',
        'address_line_1',
        'city',
        'pin_code',
        'owner_name',
        'email',
        'phone',
      ],
    );
    final val = OrgRegistrationCreate(
      legalName: $checkedConvert('legal_name', (v) => v as String),
      tradeName: $checkedConvert('trade_name', (v) => v as String?),
      businessType: $checkedConvert(
        'business_type',
        (v) => $enumDecode(_$BusinessTypeEnumMap, v),
      ),
      gstin: $checkedConvert('gstin', (v) => v as String),
      addressLine1: $checkedConvert('address_line_1', (v) => v as String),
      addressLine2: $checkedConvert('address_line_2', (v) => v as String?),
      city: $checkedConvert('city', (v) => v as String),
      pinCode: $checkedConvert('pin_code', (v) => v as String),
      ownerName: $checkedConvert('owner_name', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'legalName': 'legal_name',
    'tradeName': 'trade_name',
    'businessType': 'business_type',
    'addressLine1': 'address_line_1',
    'addressLine2': 'address_line_2',
    'pinCode': 'pin_code',
    'ownerName': 'owner_name',
  },
);

Map<String, dynamic> _$OrgRegistrationCreateToJson(
  OrgRegistrationCreate instance,
) => <String, dynamic>{
  'legal_name': instance.legalName,
  'trade_name': ?instance.tradeName,
  'business_type': _$BusinessTypeEnumMap[instance.businessType]!,
  'gstin': instance.gstin,
  'address_line_1': instance.addressLine1,
  'address_line_2': ?instance.addressLine2,
  'city': instance.city,
  'pin_code': instance.pinCode,
  'owner_name': instance.ownerName,
  'email': instance.email,
  'phone': instance.phone,
};

const _$BusinessTypeEnumMap = {
  BusinessType.proprietorship: 'proprietorship',
  BusinessType.partnership: 'partnership',
  BusinessType.llp: 'llp',
  BusinessType.privateLimited: 'private_limited',
  BusinessType.publicLimited: 'public_limited',
  BusinessType.other: 'other',
};
