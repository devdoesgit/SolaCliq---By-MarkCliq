// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChecklistCreateCWProxy {
  ChecklistCreate id(String id);

  ChecklistCreate text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChecklistCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChecklistCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  ChecklistCreate call({String id, String text});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfChecklistCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfChecklistCreate.copyWith.fieldName(...)`
class _$ChecklistCreateCWProxyImpl implements _$ChecklistCreateCWProxy {
  const _$ChecklistCreateCWProxyImpl(this._value);

  final ChecklistCreate _value;

  @override
  ChecklistCreate id(String id) => this(id: id);

  @override
  ChecklistCreate text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChecklistCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChecklistCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  ChecklistCreate call({
    Object? id = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return ChecklistCreate(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $ChecklistCreateCopyWith on ChecklistCreate {
  /// Returns a callable class that can be used as follows: `instanceOfChecklistCreate.copyWith(...)` or like so:`instanceOfChecklistCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChecklistCreateCWProxy get copyWith => _$ChecklistCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChecklistCreate _$ChecklistCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChecklistCreate', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'text']);
      final val = ChecklistCreate(
        id: $checkedConvert('id', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ChecklistCreateToJson(ChecklistCreate instance) =>
    <String, dynamic>{'id': instance.id, 'text': instance.text};
