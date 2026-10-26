// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_member_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AddMemberRequestCWProxy {
  AddMemberRequest name(String name);

  AddMemberRequest email(String email);

  AddMemberRequest role(Role role);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AddMemberRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AddMemberRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AddMemberRequest call({String name, String email, Role role});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAddMemberRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAddMemberRequest.copyWith.fieldName(...)`
class _$AddMemberRequestCWProxyImpl implements _$AddMemberRequestCWProxy {
  const _$AddMemberRequestCWProxyImpl(this._value);

  final AddMemberRequest _value;

  @override
  AddMemberRequest name(String name) => this(name: name);

  @override
  AddMemberRequest email(String email) => this(email: email);

  @override
  AddMemberRequest role(Role role) => this(role: role);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AddMemberRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AddMemberRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AddMemberRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
  }) {
    return AddMemberRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as Role,
    );
  }
}

extension $AddMemberRequestCopyWith on AddMemberRequest {
  /// Returns a callable class that can be used as follows: `instanceOfAddMemberRequest.copyWith(...)` or like so:`instanceOfAddMemberRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AddMemberRequestCWProxy get copyWith => _$AddMemberRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddMemberRequest _$AddMemberRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AddMemberRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'email', 'role']);
      final val = AddMemberRequest(
        name: $checkedConvert('name', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        role: $checkedConvert('role', (v) => $enumDecode(_$RoleEnumMap, v)),
      );
      return val;
    });

Map<String, dynamic> _$AddMemberRequestToJson(AddMemberRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'role': _$RoleEnumMap[instance.role]!,
    };

const _$RoleEnumMap = {
  Role.orgAdmin: 'org_admin',
  Role.worker: 'worker',
  Role.agent: 'agent',
  Role.customer: 'customer',
};
