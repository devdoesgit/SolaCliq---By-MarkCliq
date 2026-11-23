// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_settings_set.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminSettingsSetCWProxy {
  AdminSettingsSet upiId(String? upiId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminSettingsSet(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminSettingsSet(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminSettingsSet call({String? upiId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminSettingsSet.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminSettingsSet.copyWith.fieldName(...)`
class _$AdminSettingsSetCWProxyImpl implements _$AdminSettingsSetCWProxy {
  const _$AdminSettingsSetCWProxyImpl(this._value);

  final AdminSettingsSet _value;

  @override
  AdminSettingsSet upiId(String? upiId) => this(upiId: upiId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminSettingsSet(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminSettingsSet(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminSettingsSet call({Object? upiId = const $CopyWithPlaceholder()}) {
    return AdminSettingsSet(
      upiId: upiId == const $CopyWithPlaceholder()
          ? _value.upiId
          // ignore: cast_nullable_to_non_nullable
          : upiId as String?,
    );
  }
}

extension $AdminSettingsSetCopyWith on AdminSettingsSet {
  /// Returns a callable class that can be used as follows: `instanceOfAdminSettingsSet.copyWith(...)` or like so:`instanceOfAdminSettingsSet.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminSettingsSetCWProxy get copyWith => _$AdminSettingsSetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminSettingsSet _$AdminSettingsSetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminSettingsSet', json, ($checkedConvert) {
      final val = AdminSettingsSet(
        upiId: $checkedConvert('upi_id', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'upiId': 'upi_id'});

Map<String, dynamic> _$AdminSettingsSetToJson(AdminSettingsSet instance) =>
    <String, dynamic>{'upi_id': ?instance.upiId};
