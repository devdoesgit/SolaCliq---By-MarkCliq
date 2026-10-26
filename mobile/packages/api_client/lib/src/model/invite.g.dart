// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteCWProxy {
  Invite id(String id);

  Invite org(InviteOrg org);

  Invite role(Role role);

  Invite invitedBy(String invitedBy);

  Invite invitedAt(DateTime invitedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Invite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Invite(...).copyWith(id: 12, name: "My name")
  /// ````
  Invite call({
    String id,
    InviteOrg org,
    Role role,
    String invitedBy,
    DateTime invitedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInvite.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInvite.copyWith.fieldName(...)`
class _$InviteCWProxyImpl implements _$InviteCWProxy {
  const _$InviteCWProxyImpl(this._value);

  final Invite _value;

  @override
  Invite id(String id) => this(id: id);

  @override
  Invite org(InviteOrg org) => this(org: org);

  @override
  Invite role(Role role) => this(role: role);

  @override
  Invite invitedBy(String invitedBy) => this(invitedBy: invitedBy);

  @override
  Invite invitedAt(DateTime invitedAt) => this(invitedAt: invitedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Invite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Invite(...).copyWith(id: 12, name: "My name")
  /// ````
  Invite call({
    Object? id = const $CopyWithPlaceholder(),
    Object? org = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? invitedBy = const $CopyWithPlaceholder(),
    Object? invitedAt = const $CopyWithPlaceholder(),
  }) {
    return Invite(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      org: org == const $CopyWithPlaceholder()
          ? _value.org
          // ignore: cast_nullable_to_non_nullable
          : org as InviteOrg,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as Role,
      invitedBy: invitedBy == const $CopyWithPlaceholder()
          ? _value.invitedBy
          // ignore: cast_nullable_to_non_nullable
          : invitedBy as String,
      invitedAt: invitedAt == const $CopyWithPlaceholder()
          ? _value.invitedAt
          // ignore: cast_nullable_to_non_nullable
          : invitedAt as DateTime,
    );
  }
}

extension $InviteCopyWith on Invite {
  /// Returns a callable class that can be used as follows: `instanceOfInvite.copyWith(...)` or like so:`instanceOfInvite.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteCWProxy get copyWith => _$InviteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invite _$InviteFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Invite',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['id', 'org', 'role', 'invited_by', 'invited_at'],
    );
    final val = Invite(
      id: $checkedConvert('id', (v) => v as String),
      org: $checkedConvert(
        'org',
        (v) => InviteOrg.fromJson(v as Map<String, dynamic>),
      ),
      role: $checkedConvert('role', (v) => $enumDecode(_$RoleEnumMap, v)),
      invitedBy: $checkedConvert('invited_by', (v) => v as String),
      invitedAt: $checkedConvert(
        'invited_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'invitedBy': 'invited_by', 'invitedAt': 'invited_at'},
);

Map<String, dynamic> _$InviteToJson(Invite instance) => <String, dynamic>{
  'id': instance.id,
  'org': instance.org.toJson(),
  'role': _$RoleEnumMap[instance.role]!,
  'invited_by': instance.invitedBy,
  'invited_at': instance.invitedAt.toIso8601String(),
};

const _$RoleEnumMap = {
  Role.orgAdmin: 'org_admin',
  Role.worker: 'worker',
  Role.agent: 'agent',
  Role.customer: 'customer',
};
