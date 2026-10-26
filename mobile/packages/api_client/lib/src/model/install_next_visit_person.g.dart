// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_next_visit_person.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstallNextVisitPersonCWProxy {
  InstallNextVisitPerson name(String name);

  InstallNextVisitPerson phone(String? phone);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InstallNextVisitPerson(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InstallNextVisitPerson(...).copyWith(id: 12, name: "My name")
  /// ````
  InstallNextVisitPerson call({String name, String? phone});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInstallNextVisitPerson.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInstallNextVisitPerson.copyWith.fieldName(...)`
class _$InstallNextVisitPersonCWProxyImpl
    implements _$InstallNextVisitPersonCWProxy {
  const _$InstallNextVisitPersonCWProxyImpl(this._value);

  final InstallNextVisitPerson _value;

  @override
  InstallNextVisitPerson name(String name) => this(name: name);

  @override
  InstallNextVisitPerson phone(String? phone) => this(phone: phone);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InstallNextVisitPerson(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InstallNextVisitPerson(...).copyWith(id: 12, name: "My name")
  /// ````
  InstallNextVisitPerson call({
    Object? name = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
  }) {
    return InstallNextVisitPerson(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
    );
  }
}

extension $InstallNextVisitPersonCopyWith on InstallNextVisitPerson {
  /// Returns a callable class that can be used as follows: `instanceOfInstallNextVisitPerson.copyWith(...)` or like so:`instanceOfInstallNextVisitPerson.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstallNextVisitPersonCWProxy get copyWith =>
      _$InstallNextVisitPersonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallNextVisitPerson _$InstallNextVisitPersonFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('InstallNextVisitPerson', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = InstallNextVisitPerson(
    name: $checkedConvert('name', (v) => v as String),
    phone: $checkedConvert('phone', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$InstallNextVisitPersonToJson(
  InstallNextVisitPerson instance,
) => <String, dynamic>{'name': instance.name, 'phone': ?instance.phone};
