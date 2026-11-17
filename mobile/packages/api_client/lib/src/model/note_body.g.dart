// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_body.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NoteBodyCWProxy {
  NoteBody note(String note);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NoteBody(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NoteBody(...).copyWith(id: 12, name: "My name")
  /// ````
  NoteBody call({String note});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNoteBody.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNoteBody.copyWith.fieldName(...)`
class _$NoteBodyCWProxyImpl implements _$NoteBodyCWProxy {
  const _$NoteBodyCWProxyImpl(this._value);

  final NoteBody _value;

  @override
  NoteBody note(String note) => this(note: note);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NoteBody(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NoteBody(...).copyWith(id: 12, name: "My name")
  /// ````
  NoteBody call({Object? note = const $CopyWithPlaceholder()}) {
    return NoteBody(
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String,
    );
  }
}

extension $NoteBodyCopyWith on NoteBody {
  /// Returns a callable class that can be used as follows: `instanceOfNoteBody.copyWith(...)` or like so:`instanceOfNoteBody.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NoteBodyCWProxy get copyWith => _$NoteBodyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteBody _$NoteBodyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NoteBody', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['note']);
      final val = NoteBody(note: $checkedConvert('note', (v) => v as String));
      return val;
    });

Map<String, dynamic> _$NoteBodyToJson(NoteBody instance) => <String, dynamic>{
  'note': instance.note,
};
