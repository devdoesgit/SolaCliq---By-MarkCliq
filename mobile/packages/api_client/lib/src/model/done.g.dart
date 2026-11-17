// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'done.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DoneCWProxy {
  Done id(String id);

  Done reference(String? reference);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Done(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Done(...).copyWith(id: 12, name: "My name")
  /// ````
  Done call({String id, String? reference});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDone.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDone.copyWith.fieldName(...)`
class _$DoneCWProxyImpl implements _$DoneCWProxy {
  const _$DoneCWProxyImpl(this._value);

  final Done _value;

  @override
  Done id(String id) => this(id: id);

  @override
  Done reference(String? reference) => this(reference: reference);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Done(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Done(...).copyWith(id: 12, name: "My name")
  /// ````
  Done call({
    Object? id = const $CopyWithPlaceholder(),
    Object? reference = const $CopyWithPlaceholder(),
  }) {
    return Done(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      reference: reference == const $CopyWithPlaceholder()
          ? _value.reference
          // ignore: cast_nullable_to_non_nullable
          : reference as String?,
    );
  }
}

extension $DoneCopyWith on Done {
  /// Returns a callable class that can be used as follows: `instanceOfDone.copyWith(...)` or like so:`instanceOfDone.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DoneCWProxy get copyWith => _$DoneCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Done _$DoneFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Done', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id']);
      final val = Done(
        id: $checkedConvert('id', (v) => v as String),
        reference: $checkedConvert('reference', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$DoneToJson(Done instance) => <String, dynamic>{
  'id': instance.id,
  'reference': ?instance.reference,
};
