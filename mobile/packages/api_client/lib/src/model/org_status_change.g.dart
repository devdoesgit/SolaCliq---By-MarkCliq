// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'org_status_change.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OrgStatusChangeCWProxy {
  OrgStatusChange status(OrgStatusChangeStatusEnum status);

  OrgStatusChange note(String? note);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OrgStatusChange(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OrgStatusChange(...).copyWith(id: 12, name: "My name")
  /// ````
  OrgStatusChange call({OrgStatusChangeStatusEnum status, String? note});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfOrgStatusChange.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfOrgStatusChange.copyWith.fieldName(...)`
class _$OrgStatusChangeCWProxyImpl implements _$OrgStatusChangeCWProxy {
  const _$OrgStatusChangeCWProxyImpl(this._value);

  final OrgStatusChange _value;

  @override
  OrgStatusChange status(OrgStatusChangeStatusEnum status) =>
      this(status: status);

  @override
  OrgStatusChange note(String? note) => this(note: note);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OrgStatusChange(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OrgStatusChange(...).copyWith(id: 12, name: "My name")
  /// ````
  OrgStatusChange call({
    Object? status = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return OrgStatusChange(
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as OrgStatusChangeStatusEnum,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $OrgStatusChangeCopyWith on OrgStatusChange {
  /// Returns a callable class that can be used as follows: `instanceOfOrgStatusChange.copyWith(...)` or like so:`instanceOfOrgStatusChange.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OrgStatusChangeCWProxy get copyWith => _$OrgStatusChangeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrgStatusChange _$OrgStatusChangeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OrgStatusChange', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['status']);
      final val = OrgStatusChange(
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$OrgStatusChangeStatusEnumEnumMap, v),
        ),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$OrgStatusChangeToJson(OrgStatusChange instance) =>
    <String, dynamic>{
      'status': _$OrgStatusChangeStatusEnumEnumMap[instance.status]!,
      'note': ?instance.note,
    };

const _$OrgStatusChangeStatusEnumEnumMap = {
  OrgStatusChangeStatusEnum.active: 'active',
  OrgStatusChangeStatusEnum.rejected: 'rejected',
  OrgStatusChangeStatusEnum.suspended: 'suspended',
};
