// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PersonCWProxy {
  Person name(String name);

  Person role(String? role);

  Person you(bool? you);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Person(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Person(...).copyWith(id: 12, name: "My name")
  /// ````
  Person call({String name, String? role, bool? you});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPerson.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPerson.copyWith.fieldName(...)`
class _$PersonCWProxyImpl implements _$PersonCWProxy {
  const _$PersonCWProxyImpl(this._value);

  final Person _value;

  @override
  Person name(String name) => this(name: name);

  @override
  Person role(String? role) => this(role: role);

  @override
  Person you(bool? you) => this(you: you);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Person(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Person(...).copyWith(id: 12, name: "My name")
  /// ````
  Person call({
    Object? name = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? you = const $CopyWithPlaceholder(),
  }) {
    return Person(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as String?,
      you: you == const $CopyWithPlaceholder()
          ? _value.you
          // ignore: cast_nullable_to_non_nullable
          : you as bool?,
    );
  }
}

extension $PersonCopyWith on Person {
  /// Returns a callable class that can be used as follows: `instanceOfPerson.copyWith(...)` or like so:`instanceOfPerson.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PersonCWProxy get copyWith => _$PersonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Person', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = Person(
        name: $checkedConvert('name', (v) => v as String),
        role: $checkedConvert('role', (v) => v as String?),
        you: $checkedConvert('you', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
  'name': instance.name,
  'role': ?instance.role,
  'you': ?instance.you,
};
