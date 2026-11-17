// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SlotCreateCWProxy {
  SlotCreate hint(String? hint);

  SlotCreate id(String id);

  SlotCreate label(String label);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SlotCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SlotCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  SlotCreate call({String? hint, String id, String label});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSlotCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSlotCreate.copyWith.fieldName(...)`
class _$SlotCreateCWProxyImpl implements _$SlotCreateCWProxy {
  const _$SlotCreateCWProxyImpl(this._value);

  final SlotCreate _value;

  @override
  SlotCreate hint(String? hint) => this(hint: hint);

  @override
  SlotCreate id(String id) => this(id: id);

  @override
  SlotCreate label(String label) => this(label: label);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SlotCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SlotCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  SlotCreate call({
    Object? hint = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
  }) {
    return SlotCreate(
      hint: hint == const $CopyWithPlaceholder()
          ? _value.hint
          // ignore: cast_nullable_to_non_nullable
          : hint as String?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
    );
  }
}

extension $SlotCreateCopyWith on SlotCreate {
  /// Returns a callable class that can be used as follows: `instanceOfSlotCreate.copyWith(...)` or like so:`instanceOfSlotCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SlotCreateCWProxy get copyWith => _$SlotCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlotCreate _$SlotCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SlotCreate', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'label']);
      final val = SlotCreate(
        hint: $checkedConvert('hint', (v) => v as String?),
        id: $checkedConvert('id', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SlotCreateToJson(SlotCreate instance) =>
    <String, dynamic>{
      'hint': ?instance.hint,
      'id': instance.id,
      'label': instance.label,
    };
