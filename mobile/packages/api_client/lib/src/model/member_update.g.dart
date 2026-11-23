// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemberUpdateCWProxy {
  MemberUpdate role(MemberUpdateRoleEnum? role);

  MemberUpdate payType(PayType? payType);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MemberUpdate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MemberUpdate(...).copyWith(id: 12, name: "My name")
  /// ````
  MemberUpdate call({MemberUpdateRoleEnum? role, PayType? payType});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMemberUpdate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMemberUpdate.copyWith.fieldName(...)`
class _$MemberUpdateCWProxyImpl implements _$MemberUpdateCWProxy {
  const _$MemberUpdateCWProxyImpl(this._value);

  final MemberUpdate _value;

  @override
  MemberUpdate role(MemberUpdateRoleEnum? role) => this(role: role);

  @override
  MemberUpdate payType(PayType? payType) => this(payType: payType);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MemberUpdate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MemberUpdate(...).copyWith(id: 12, name: "My name")
  /// ````
  MemberUpdate call({
    Object? role = const $CopyWithPlaceholder(),
    Object? payType = const $CopyWithPlaceholder(),
  }) {
    return MemberUpdate(
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as MemberUpdateRoleEnum?,
      payType: payType == const $CopyWithPlaceholder()
          ? _value.payType
          // ignore: cast_nullable_to_non_nullable
          : payType as PayType?,
    );
  }
}

extension $MemberUpdateCopyWith on MemberUpdate {
  /// Returns a callable class that can be used as follows: `instanceOfMemberUpdate.copyWith(...)` or like so:`instanceOfMemberUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MemberUpdateCWProxy get copyWith => _$MemberUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberUpdate _$MemberUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MemberUpdate', json, ($checkedConvert) {
      final val = MemberUpdate(
        role: $checkedConvert(
          'role',
          (v) => $enumDecodeNullable(_$MemberUpdateRoleEnumEnumMap, v),
        ),
        payType: $checkedConvert(
          'pay_type',
          (v) => $enumDecodeNullable(_$PayTypeEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'payType': 'pay_type'});

Map<String, dynamic> _$MemberUpdateToJson(MemberUpdate instance) =>
    <String, dynamic>{
      'role': ?_$MemberUpdateRoleEnumEnumMap[instance.role],
      'pay_type': ?_$PayTypeEnumMap[instance.payType],
    };

const _$MemberUpdateRoleEnumEnumMap = {
  MemberUpdateRoleEnum.worker: 'worker',
  MemberUpdateRoleEnum.agent: 'agent',
};

const _$PayTypeEnumMap = {
  PayType.commission: 'commission',
  PayType.salary: 'salary',
};
