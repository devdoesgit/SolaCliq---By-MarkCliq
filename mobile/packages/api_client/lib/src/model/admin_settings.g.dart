// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminSettingsCWProxy {
  AdminSettings upiId(String? upiId);

  AdminSettings stages(List<String> stages);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminSettings(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminSettings(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminSettings call({String? upiId, List<String> stages});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminSettings.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminSettings.copyWith.fieldName(...)`
class _$AdminSettingsCWProxyImpl implements _$AdminSettingsCWProxy {
  const _$AdminSettingsCWProxyImpl(this._value);

  final AdminSettings _value;

  @override
  AdminSettings upiId(String? upiId) => this(upiId: upiId);

  @override
  AdminSettings stages(List<String> stages) => this(stages: stages);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminSettings(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminSettings(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminSettings call({
    Object? upiId = const $CopyWithPlaceholder(),
    Object? stages = const $CopyWithPlaceholder(),
  }) {
    return AdminSettings(
      upiId: upiId == const $CopyWithPlaceholder()
          ? _value.upiId
          // ignore: cast_nullable_to_non_nullable
          : upiId as String?,
      stages: stages == const $CopyWithPlaceholder()
          ? _value.stages
          // ignore: cast_nullable_to_non_nullable
          : stages as List<String>,
    );
  }
}

extension $AdminSettingsCopyWith on AdminSettings {
  /// Returns a callable class that can be used as follows: `instanceOfAdminSettings.copyWith(...)` or like so:`instanceOfAdminSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminSettingsCWProxy get copyWith => _$AdminSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminSettings _$AdminSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminSettings', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['stages']);
      final val = AdminSettings(
        upiId: $checkedConvert('upi_id', (v) => v as String?),
        stages: $checkedConvert(
          'stages',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'upiId': 'upi_id'});

Map<String, dynamic> _$AdminSettingsToJson(AdminSettings instance) =>
    <String, dynamic>{'upi_id': ?instance.upiId, 'stages': instance.stages};
