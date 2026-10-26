// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_org.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MembershipOrgCWProxy {
  MembershipOrg id(String id);

  MembershipOrg name(String name);

  MembershipOrg status(OrgStatus status);

  MembershipOrg phone(String? phone);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MembershipOrg(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MembershipOrg(...).copyWith(id: 12, name: "My name")
  /// ````
  MembershipOrg call({String id, String name, OrgStatus status, String? phone});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMembershipOrg.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMembershipOrg.copyWith.fieldName(...)`
class _$MembershipOrgCWProxyImpl implements _$MembershipOrgCWProxy {
  const _$MembershipOrgCWProxyImpl(this._value);

  final MembershipOrg _value;

  @override
  MembershipOrg id(String id) => this(id: id);

  @override
  MembershipOrg name(String name) => this(name: name);

  @override
  MembershipOrg status(OrgStatus status) => this(status: status);

  @override
  MembershipOrg phone(String? phone) => this(phone: phone);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MembershipOrg(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MembershipOrg(...).copyWith(id: 12, name: "My name")
  /// ````
  MembershipOrg call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
  }) {
    return MembershipOrg(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as OrgStatus,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
    );
  }
}

extension $MembershipOrgCopyWith on MembershipOrg {
  /// Returns a callable class that can be used as follows: `instanceOfMembershipOrg.copyWith(...)` or like so:`instanceOfMembershipOrg.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MembershipOrgCWProxy get copyWith => _$MembershipOrgCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MembershipOrg _$MembershipOrgFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MembershipOrg', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name', 'status']);
      final val = MembershipOrg(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$OrgStatusEnumMap, v),
        ),
        phone: $checkedConvert('phone', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$MembershipOrgToJson(MembershipOrg instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': _$OrgStatusEnumMap[instance.status]!,
      'phone': ?instance.phone,
    };

const _$OrgStatusEnumMap = {
  OrgStatus.pending: 'pending',
  OrgStatus.active: 'active',
  OrgStatus.suspended: 'suspended',
};
