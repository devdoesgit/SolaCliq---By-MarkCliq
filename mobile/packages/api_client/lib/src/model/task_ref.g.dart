// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_ref.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskRefCWProxy {
  TaskRef id(String id);

  TaskRef title(String title);

  TaskRef customerName(String customerName);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskRef(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskRef(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskRef call({String id, String title, String customerName});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskRef.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskRef.copyWith.fieldName(...)`
class _$TaskRefCWProxyImpl implements _$TaskRefCWProxy {
  const _$TaskRefCWProxyImpl(this._value);

  final TaskRef _value;

  @override
  TaskRef id(String id) => this(id: id);

  @override
  TaskRef title(String title) => this(title: title);

  @override
  TaskRef customerName(String customerName) => this(customerName: customerName);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskRef(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskRef(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskRef call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? customerName = const $CopyWithPlaceholder(),
  }) {
    return TaskRef(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      customerName: customerName == const $CopyWithPlaceholder()
          ? _value.customerName
          // ignore: cast_nullable_to_non_nullable
          : customerName as String,
    );
  }
}

extension $TaskRefCopyWith on TaskRef {
  /// Returns a callable class that can be used as follows: `instanceOfTaskRef.copyWith(...)` or like so:`instanceOfTaskRef.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskRefCWProxy get copyWith => _$TaskRefCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskRef _$TaskRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskRef', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'title', 'customer_name']);
      final val = TaskRef(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        customerName: $checkedConvert('customer_name', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'customerName': 'customer_name'});

Map<String, dynamic> _$TaskRefToJson(TaskRef instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'customer_name': instance.customerName,
};
