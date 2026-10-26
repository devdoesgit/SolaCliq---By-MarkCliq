// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_details.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PersonalDetailsCWProxy {
  PersonalDetails phone(String? phone);

  PersonalDetails address(String? address);

  PersonalDetails emergencyContact(String? emergencyContact);

  PersonalDetails bank(PayoutBank? bank);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalDetails(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalDetails(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalDetails call({
    String? phone,
    String? address,
    String? emergencyContact,
    PayoutBank? bank,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPersonalDetails.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPersonalDetails.copyWith.fieldName(...)`
class _$PersonalDetailsCWProxyImpl implements _$PersonalDetailsCWProxy {
  const _$PersonalDetailsCWProxyImpl(this._value);

  final PersonalDetails _value;

  @override
  PersonalDetails phone(String? phone) => this(phone: phone);

  @override
  PersonalDetails address(String? address) => this(address: address);

  @override
  PersonalDetails emergencyContact(String? emergencyContact) =>
      this(emergencyContact: emergencyContact);

  @override
  PersonalDetails bank(PayoutBank? bank) => this(bank: bank);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalDetails(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalDetails(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalDetails call({
    Object? phone = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? emergencyContact = const $CopyWithPlaceholder(),
    Object? bank = const $CopyWithPlaceholder(),
  }) {
    return PersonalDetails(
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
      address: address == const $CopyWithPlaceholder()
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String?,
      emergencyContact: emergencyContact == const $CopyWithPlaceholder()
          ? _value.emergencyContact
          // ignore: cast_nullable_to_non_nullable
          : emergencyContact as String?,
      bank: bank == const $CopyWithPlaceholder()
          ? _value.bank
          // ignore: cast_nullable_to_non_nullable
          : bank as PayoutBank?,
    );
  }
}

extension $PersonalDetailsCopyWith on PersonalDetails {
  /// Returns a callable class that can be used as follows: `instanceOfPersonalDetails.copyWith(...)` or like so:`instanceOfPersonalDetails.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PersonalDetailsCWProxy get copyWith => _$PersonalDetailsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalDetails _$PersonalDetailsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PersonalDetails', json, ($checkedConvert) {
      final val = PersonalDetails(
        phone: $checkedConvert('phone', (v) => v as String?),
        address: $checkedConvert('address', (v) => v as String?),
        emergencyContact: $checkedConvert(
          'emergency_contact',
          (v) => v as String?,
        ),
        bank: $checkedConvert(
          'bank',
          (v) =>
              v == null ? null : PayoutBank.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'emergencyContact': 'emergency_contact'});

Map<String, dynamic> _$PersonalDetailsToJson(PersonalDetails instance) =>
    <String, dynamic>{
      'phone': ?instance.phone,
      'address': ?instance.address,
      'emergency_contact': ?instance.emergencyContact,
      'bank': ?instance.bank?.toJson(),
    };
