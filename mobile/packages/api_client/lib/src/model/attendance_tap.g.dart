// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_tap.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendanceTapCWProxy {
  AttendanceTap at(DateTime at);

  AttendanceTap sentLate(bool sentLate);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceTap(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceTap(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceTap call({DateTime at, bool sentLate});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttendanceTap.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttendanceTap.copyWith.fieldName(...)`
class _$AttendanceTapCWProxyImpl implements _$AttendanceTapCWProxy {
  const _$AttendanceTapCWProxyImpl(this._value);

  final AttendanceTap _value;

  @override
  AttendanceTap at(DateTime at) => this(at: at);

  @override
  AttendanceTap sentLate(bool sentLate) => this(sentLate: sentLate);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceTap(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceTap(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceTap call({
    Object? at = const $CopyWithPlaceholder(),
    Object? sentLate = const $CopyWithPlaceholder(),
  }) {
    return AttendanceTap(
      at: at == const $CopyWithPlaceholder()
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
      sentLate: sentLate == const $CopyWithPlaceholder()
          ? _value.sentLate
          // ignore: cast_nullable_to_non_nullable
          : sentLate as bool,
    );
  }
}

extension $AttendanceTapCopyWith on AttendanceTap {
  /// Returns a callable class that can be used as follows: `instanceOfAttendanceTap.copyWith(...)` or like so:`instanceOfAttendanceTap.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendanceTapCWProxy get copyWith => _$AttendanceTapCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceTap _$AttendanceTapFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AttendanceTap', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['at', 'sent_late']);
      final val = AttendanceTap(
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        sentLate: $checkedConvert('sent_late', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'sentLate': 'sent_late'});

Map<String, dynamic> _$AttendanceTapToJson(AttendanceTap instance) =>
    <String, dynamic>{
      'at': instance.at.toIso8601String(),
      'sent_late': instance.sentLate,
    };
