// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_stage.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstallStageCWProxy {
  InstallStage name(String name);

  InstallStage detail(String? detail);

  InstallStage status(InstallStageStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InstallStage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InstallStage(...).copyWith(id: 12, name: "My name")
  /// ````
  InstallStage call({
    String name,
    String? detail,
    InstallStageStatusEnum status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInstallStage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInstallStage.copyWith.fieldName(...)`
class _$InstallStageCWProxyImpl implements _$InstallStageCWProxy {
  const _$InstallStageCWProxyImpl(this._value);

  final InstallStage _value;

  @override
  InstallStage name(String name) => this(name: name);

  @override
  InstallStage detail(String? detail) => this(detail: detail);

  @override
  InstallStage status(InstallStageStatusEnum status) => this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InstallStage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InstallStage(...).copyWith(id: 12, name: "My name")
  /// ````
  InstallStage call({
    Object? name = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return InstallStage(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as InstallStageStatusEnum,
    );
  }
}

extension $InstallStageCopyWith on InstallStage {
  /// Returns a callable class that can be used as follows: `instanceOfInstallStage.copyWith(...)` or like so:`instanceOfInstallStage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstallStageCWProxy get copyWith => _$InstallStageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallStage _$InstallStageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InstallStage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'status']);
      final val = InstallStage(
        name: $checkedConvert('name', (v) => v as String),
        detail: $checkedConvert('detail', (v) => v as String?),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$InstallStageStatusEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InstallStageToJson(InstallStage instance) =>
    <String, dynamic>{
      'name': instance.name,
      'detail': ?instance.detail,
      'status': _$InstallStageStatusEnumEnumMap[instance.status]!,
    };

const _$InstallStageStatusEnumEnumMap = {
  InstallStageStatusEnum.done: 'done',
  InstallStageStatusEnum.next: 'next',
  InstallStageStatusEnum.upcoming: 'upcoming',
};
