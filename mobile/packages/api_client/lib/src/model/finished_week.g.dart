// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finished_week.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FinishedWeekCWProxy {
  FinishedWeek from(String from);

  FinishedWeek count(int count);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FinishedWeek(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FinishedWeek(...).copyWith(id: 12, name: "My name")
  /// ````
  FinishedWeek call({String from, int count});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFinishedWeek.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFinishedWeek.copyWith.fieldName(...)`
class _$FinishedWeekCWProxyImpl implements _$FinishedWeekCWProxy {
  const _$FinishedWeekCWProxyImpl(this._value);

  final FinishedWeek _value;

  @override
  FinishedWeek from(String from) => this(from: from);

  @override
  FinishedWeek count(int count) => this(count: count);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FinishedWeek(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FinishedWeek(...).copyWith(id: 12, name: "My name")
  /// ````
  FinishedWeek call({
    Object? from = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
  }) {
    return FinishedWeek(
      from: from == const $CopyWithPlaceholder()
          ? _value.from
          // ignore: cast_nullable_to_non_nullable
          : from as String,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
    );
  }
}

extension $FinishedWeekCopyWith on FinishedWeek {
  /// Returns a callable class that can be used as follows: `instanceOfFinishedWeek.copyWith(...)` or like so:`instanceOfFinishedWeek.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FinishedWeekCWProxy get copyWith => _$FinishedWeekCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinishedWeek _$FinishedWeekFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FinishedWeek', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['from', 'count']);
      final val = FinishedWeek(
        from: $checkedConvert('from', (v) => v as String),
        count: $checkedConvert('count', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$FinishedWeekToJson(FinishedWeek instance) =>
    <String, dynamic>{'from': instance.from, 'count': instance.count};
