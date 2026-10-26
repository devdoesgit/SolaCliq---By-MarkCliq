// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_request_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AccessRequestCreateCWProxy {
  AccessRequestCreate companyName(String companyName);

  AccessRequestCreate ownerName(String ownerName);

  AccessRequestCreate phone(String phone);

  AccessRequestCreate city(String city);

  AccessRequestCreate email(String email);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccessRequestCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccessRequestCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  AccessRequestCreate call({
    String companyName,
    String ownerName,
    String phone,
    String city,
    String email,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAccessRequestCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAccessRequestCreate.copyWith.fieldName(...)`
class _$AccessRequestCreateCWProxyImpl implements _$AccessRequestCreateCWProxy {
  const _$AccessRequestCreateCWProxyImpl(this._value);

  final AccessRequestCreate _value;

  @override
  AccessRequestCreate companyName(String companyName) =>
      this(companyName: companyName);

  @override
  AccessRequestCreate ownerName(String ownerName) => this(ownerName: ownerName);

  @override
  AccessRequestCreate phone(String phone) => this(phone: phone);

  @override
  AccessRequestCreate city(String city) => this(city: city);

  @override
  AccessRequestCreate email(String email) => this(email: email);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccessRequestCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccessRequestCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  AccessRequestCreate call({
    Object? companyName = const $CopyWithPlaceholder(),
    Object? ownerName = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? city = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
  }) {
    return AccessRequestCreate(
      companyName: companyName == const $CopyWithPlaceholder()
          ? _value.companyName
          // ignore: cast_nullable_to_non_nullable
          : companyName as String,
      ownerName: ownerName == const $CopyWithPlaceholder()
          ? _value.ownerName
          // ignore: cast_nullable_to_non_nullable
          : ownerName as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
      city: city == const $CopyWithPlaceholder()
          ? _value.city
          // ignore: cast_nullable_to_non_nullable
          : city as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
    );
  }
}

extension $AccessRequestCreateCopyWith on AccessRequestCreate {
  /// Returns a callable class that can be used as follows: `instanceOfAccessRequestCreate.copyWith(...)` or like so:`instanceOfAccessRequestCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AccessRequestCreateCWProxy get copyWith =>
      _$AccessRequestCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessRequestCreate _$AccessRequestCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AccessRequestCreate',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'company_name',
            'owner_name',
            'phone',
            'city',
            'email',
          ],
        );
        final val = AccessRequestCreate(
          companyName: $checkedConvert('company_name', (v) => v as String),
          ownerName: $checkedConvert('owner_name', (v) => v as String),
          phone: $checkedConvert('phone', (v) => v as String),
          city: $checkedConvert('city', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'companyName': 'company_name',
        'ownerName': 'owner_name',
      },
    );

Map<String, dynamic> _$AccessRequestCreateToJson(
  AccessRequestCreate instance,
) => <String, dynamic>{
  'company_name': instance.companyName,
  'owner_name': instance.ownerName,
  'phone': instance.phone,
  'city': instance.city,
  'email': instance.email,
};
