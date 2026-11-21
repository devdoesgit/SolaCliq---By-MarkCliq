// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_tap_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendanceTapCreateCWProxy {
  AttendanceTapCreate phoneAt(DateTime phoneAt);

  AttendanceTapCreate sentAt(DateTime sentAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceTapCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceTapCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceTapCreate call({DateTime phoneAt, DateTime sentAt});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttendanceTapCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttendanceTapCreate.copyWith.fieldName(...)`
class _$AttendanceTapCreateCWProxyImpl implements _$AttendanceTapCreateCWProxy {
  const _$AttendanceTapCreateCWProxyImpl(this._value);

  final AttendanceTapCreate _value;

  @override
  AttendanceTapCreate phoneAt(DateTime phoneAt) => this(phoneAt: phoneAt);

  @override
  AttendanceTapCreate sentAt(DateTime sentAt) => this(sentAt: sentAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceTapCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceTapCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceTapCreate call({
    Object? phoneAt = const $CopyWithPlaceholder(),
    Object? sentAt = const $CopyWithPlaceholder(),
  }) {
    return AttendanceTapCreate(
      phoneAt: phoneAt == const $CopyWithPlaceholder()
          ? _value.phoneAt
          // ignore: cast_nullable_to_non_nullable
          : phoneAt as DateTime,
      sentAt: sentAt == const $CopyWithPlaceholder()
          ? _value.sentAt
          // ignore: cast_nullable_to_non_nullable
          : sentAt as DateTime,
    );
  }
}

extension $AttendanceTapCreateCopyWith on AttendanceTapCreate {
  /// Returns a callable class that can be used as follows: `instanceOfAttendanceTapCreate.copyWith(...)` or like so:`instanceOfAttendanceTapCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendanceTapCreateCWProxy get copyWith =>
      _$AttendanceTapCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceTapCreate _$AttendanceTapCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AttendanceTapCreate', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['phone_at', 'sent_at']);
      final val = AttendanceTapCreate(
        phoneAt: $checkedConvert(
          'phone_at',
          (v) => DateTime.parse(v as String),
        ),
        sentAt: $checkedConvert('sent_at', (v) => DateTime.parse(v as String)),
      );
      return val;
    }, fieldKeyMap: const {'phoneAt': 'phone_at', 'sentAt': 'sent_at'});

Map<String, dynamic> _$AttendanceTapCreateToJson(
  AttendanceTapCreate instance,
) => <String, dynamic>{
  'phone_at': instance.phoneAt.toIso8601String(),
  'sent_at': instance.sentAt.toIso8601String(),
};
