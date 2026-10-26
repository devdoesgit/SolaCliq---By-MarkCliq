// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_org.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteOrgCWProxy {
  InviteOrg id(String id);

  InviteOrg name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InviteOrg(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InviteOrg(...).copyWith(id: 12, name: "My name")
  /// ````
  InviteOrg call({String id, String name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInviteOrg.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInviteOrg.copyWith.fieldName(...)`
class _$InviteOrgCWProxyImpl implements _$InviteOrgCWProxy {
  const _$InviteOrgCWProxyImpl(this._value);

  final InviteOrg _value;

  @override
  InviteOrg id(String id) => this(id: id);

  @override
  InviteOrg name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InviteOrg(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InviteOrg(...).copyWith(id: 12, name: "My name")
  /// ````
  InviteOrg call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return InviteOrg(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $InviteOrgCopyWith on InviteOrg {
  /// Returns a callable class that can be used as follows: `instanceOfInviteOrg.copyWith(...)` or like so:`instanceOfInviteOrg.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteOrgCWProxy get copyWith => _$InviteOrgCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteOrg _$InviteOrgFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InviteOrg', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name']);
      final val = InviteOrg(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$InviteOrgToJson(InviteOrg instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};
