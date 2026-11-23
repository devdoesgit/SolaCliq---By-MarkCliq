// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_stage.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminStageCWProxy {
  AdminStage index(int index);

  AdminStage count(int count);

  AdminStage name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminStage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminStage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminStage call({int index, int count, String name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminStage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminStage.copyWith.fieldName(...)`
class _$AdminStageCWProxyImpl implements _$AdminStageCWProxy {
  const _$AdminStageCWProxyImpl(this._value);

  final AdminStage _value;

  @override
  AdminStage index(int index) => this(index: index);

  @override
  AdminStage count(int count) => this(count: count);

  @override
  AdminStage name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminStage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminStage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminStage call({
    Object? index = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return AdminStage(
      index: index == const $CopyWithPlaceholder()
          ? _value.index
          // ignore: cast_nullable_to_non_nullable
          : index as int,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $AdminStageCopyWith on AdminStage {
  /// Returns a callable class that can be used as follows: `instanceOfAdminStage.copyWith(...)` or like so:`instanceOfAdminStage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminStageCWProxy get copyWith => _$AdminStageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminStage _$AdminStageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminStage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['index', 'count', 'name']);
      final val = AdminStage(
        index: $checkedConvert('index', (v) => (v as num).toInt()),
        count: $checkedConvert('count', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AdminStageToJson(AdminStage instance) =>
    <String, dynamic>{
      'index': instance.index,
      'count': instance.count,
      'name': instance.name,
    };
