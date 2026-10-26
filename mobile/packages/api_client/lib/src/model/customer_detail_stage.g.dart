// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_detail_stage.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerDetailStageCWProxy {
  CustomerDetailStage index(int index);

  CustomerDetailStage count(int count);

  CustomerDetailStage label(String label);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerDetailStage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerDetailStage(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerDetailStage call({int index, int count, String label});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCustomerDetailStage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCustomerDetailStage.copyWith.fieldName(...)`
class _$CustomerDetailStageCWProxyImpl implements _$CustomerDetailStageCWProxy {
  const _$CustomerDetailStageCWProxyImpl(this._value);

  final CustomerDetailStage _value;

  @override
  CustomerDetailStage index(int index) => this(index: index);

  @override
  CustomerDetailStage count(int count) => this(count: count);

  @override
  CustomerDetailStage label(String label) => this(label: label);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerDetailStage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerDetailStage(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerDetailStage call({
    Object? index = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
  }) {
    return CustomerDetailStage(
      index: index == const $CopyWithPlaceholder()
          ? _value.index
          // ignore: cast_nullable_to_non_nullable
          : index as int,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
    );
  }
}

extension $CustomerDetailStageCopyWith on CustomerDetailStage {
  /// Returns a callable class that can be used as follows: `instanceOfCustomerDetailStage.copyWith(...)` or like so:`instanceOfCustomerDetailStage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerDetailStageCWProxy get copyWith =>
      _$CustomerDetailStageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerDetailStage _$CustomerDetailStageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CustomerDetailStage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['index', 'count', 'label']);
      final val = CustomerDetailStage(
        index: $checkedConvert('index', (v) => (v as num).toInt()),
        count: $checkedConvert('count', (v) => (v as num).toInt()),
        label: $checkedConvert('label', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CustomerDetailStageToJson(
  CustomerDetailStage instance,
) => <String, dynamic>{
  'index': instance.index,
  'count': instance.count,
  'label': instance.label,
};
