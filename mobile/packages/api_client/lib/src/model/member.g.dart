// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemberCWProxy {
  Member userId(String userId);

  Member name(String name);

  Member email(String email);

  Member role(Role role);

  Member status(MemberStatus status);

  Member addedAt(DateTime addedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Member(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Member(...).copyWith(id: 12, name: "My name")
  /// ````
  Member call({
    String userId,
    String name,
    String email,
    Role role,
    MemberStatus status,
    DateTime addedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMember.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMember.copyWith.fieldName(...)`
class _$MemberCWProxyImpl implements _$MemberCWProxy {
  const _$MemberCWProxyImpl(this._value);

  final Member _value;

  @override
  Member userId(String userId) => this(userId: userId);

  @override
  Member name(String name) => this(name: name);

  @override
  Member email(String email) => this(email: email);

  @override
  Member role(Role role) => this(role: role);

  @override
  Member status(MemberStatus status) => this(status: status);

  @override
  Member addedAt(DateTime addedAt) => this(addedAt: addedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Member(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Member(...).copyWith(id: 12, name: "My name")
  /// ````
  Member call({
    Object? userId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? addedAt = const $CopyWithPlaceholder(),
  }) {
    return Member(
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
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
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as MemberStatus,
      addedAt: addedAt == const $CopyWithPlaceholder()
          ? _value.addedAt
          // ignore: cast_nullable_to_non_nullable
          : addedAt as DateTime,
    );
  }
}

extension $MemberCopyWith on Member {
  /// Returns a callable class that can be used as follows: `instanceOfMember.copyWith(...)` or like so:`instanceOfMember.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MemberCWProxy get copyWith => _$MemberCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Member _$MemberFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Member',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'user_id',
        'name',
        'email',
        'role',
        'status',
        'added_at',
      ],
    );
    final val = Member(
      userId: $checkedConvert('user_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String),
      role: $checkedConvert('role', (v) => $enumDecode(_$RoleEnumMap, v)),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$MemberStatusEnumMap, v),
      ),
      addedAt: $checkedConvert('added_at', (v) => DateTime.parse(v as String)),
    );
    return val;
  },
  fieldKeyMap: const {'userId': 'user_id', 'addedAt': 'added_at'},
);

Map<String, dynamic> _$MemberToJson(Member instance) => <String, dynamic>{
  'user_id': instance.userId,
  'name': instance.name,
  'email': instance.email,
  'role': _$RoleEnumMap[instance.role]!,
  'status': _$MemberStatusEnumMap[instance.status]!,
  'added_at': instance.addedAt.toIso8601String(),
};

const _$RoleEnumMap = {
  Role.orgAdmin: 'org_admin',
  Role.worker: 'worker',
  Role.agent: 'agent',
  Role.customer: 'customer',
};

const _$MemberStatusEnumMap = {
  MemberStatus.invited: 'invited',
  MemberStatus.active: 'active',
};
