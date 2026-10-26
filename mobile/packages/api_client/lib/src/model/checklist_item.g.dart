// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChecklistItemCWProxy {
  ChecklistItem id(String id);

  ChecklistItem text(String text);

  ChecklistItem done(bool done);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChecklistItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChecklistItem(...).copyWith(id: 12, name: "My name")
  /// ````
  ChecklistItem call({String id, String text, bool done});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfChecklistItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfChecklistItem.copyWith.fieldName(...)`
class _$ChecklistItemCWProxyImpl implements _$ChecklistItemCWProxy {
  const _$ChecklistItemCWProxyImpl(this._value);

  final ChecklistItem _value;

  @override
  ChecklistItem id(String id) => this(id: id);

  @override
  ChecklistItem text(String text) => this(text: text);

  @override
  ChecklistItem done(bool done) => this(done: done);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChecklistItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChecklistItem(...).copyWith(id: 12, name: "My name")
  /// ````
  ChecklistItem call({
    Object? id = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? done = const $CopyWithPlaceholder(),
  }) {
    return ChecklistItem(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      done: done == const $CopyWithPlaceholder()
          ? _value.done
          // ignore: cast_nullable_to_non_nullable
          : done as bool,
    );
  }
}

extension $ChecklistItemCopyWith on ChecklistItem {
  /// Returns a callable class that can be used as follows: `instanceOfChecklistItem.copyWith(...)` or like so:`instanceOfChecklistItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChecklistItemCWProxy get copyWith => _$ChecklistItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChecklistItem _$ChecklistItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChecklistItem', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'text', 'done']);
      final val = ChecklistItem(
        id: $checkedConvert('id', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String),
        done: $checkedConvert('done', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$ChecklistItemToJson(ChecklistItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'done': instance.done,
    };
