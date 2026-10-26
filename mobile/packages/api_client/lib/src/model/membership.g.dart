// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MembershipCWProxy {
  Membership org(MembershipOrg org);

  Membership role(Role role);

  Membership payType(MembershipPayTypeEnum? payType);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Membership(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Membership(...).copyWith(id: 12, name: "My name")
  /// ````
  Membership call({
    MembershipOrg org,
    Role role,
    MembershipPayTypeEnum? payType,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMembership.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMembership.copyWith.fieldName(...)`
class _$MembershipCWProxyImpl implements _$MembershipCWProxy {
  const _$MembershipCWProxyImpl(this._value);

  final Membership _value;

  @override
  Membership org(MembershipOrg org) => this(org: org);

  @override
  Membership role(Role role) => this(role: role);

  @override
  Membership payType(MembershipPayTypeEnum? payType) => this(payType: payType);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Membership(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Membership(...).copyWith(id: 12, name: "My name")
  /// ````
  Membership call({
    Object? org = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? payType = const $CopyWithPlaceholder(),
  }) {
    return Membership(
      org: org == const $CopyWithPlaceholder()
          ? _value.org
          // ignore: cast_nullable_to_non_nullable
          : org as MembershipOrg,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as Role,
      payType: payType == const $CopyWithPlaceholder()
          ? _value.payType
          // ignore: cast_nullable_to_non_nullable
          : payType as MembershipPayTypeEnum?,
    );
  }
}

extension $MembershipCopyWith on Membership {
  /// Returns a callable class that can be used as follows: `instanceOfMembership.copyWith(...)` or like so:`instanceOfMembership.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MembershipCWProxy get copyWith => _$MembershipCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Membership _$MembershipFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Membership', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['org', 'role']);
      final val = Membership(
        org: $checkedConvert(
          'org',
          (v) => MembershipOrg.fromJson(v as Map<String, dynamic>),
        ),
        role: $checkedConvert('role', (v) => $enumDecode(_$RoleEnumMap, v)),
        payType: $checkedConvert(
          'pay_type',
          (v) => $enumDecodeNullable(_$MembershipPayTypeEnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'payType': 'pay_type'});

Map<String, dynamic> _$MembershipToJson(Membership instance) =>
    <String, dynamic>{
      'org': instance.org.toJson(),
      'role': _$RoleEnumMap[instance.role]!,
      'pay_type': ?_$MembershipPayTypeEnumEnumMap[instance.payType],
    };

const _$RoleEnumMap = {
  Role.orgAdmin: 'org_admin',
  Role.worker: 'worker',
  Role.agent: 'agent',
  Role.customer: 'customer',
};

const _$MembershipPayTypeEnumEnumMap = {
  MembershipPayTypeEnum.commission: 'commission',
  MembershipPayTypeEnum.salary: 'salary',
};
