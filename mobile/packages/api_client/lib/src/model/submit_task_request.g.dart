// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_task_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubmitTaskRequestCWProxy {
  SubmitTaskRequest note(String? note);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubmitTaskRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubmitTaskRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SubmitTaskRequest call({String? note});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSubmitTaskRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSubmitTaskRequest.copyWith.fieldName(...)`
class _$SubmitTaskRequestCWProxyImpl implements _$SubmitTaskRequestCWProxy {
  const _$SubmitTaskRequestCWProxyImpl(this._value);

  final SubmitTaskRequest _value;

  @override
  SubmitTaskRequest note(String? note) => this(note: note);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubmitTaskRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubmitTaskRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SubmitTaskRequest call({Object? note = const $CopyWithPlaceholder()}) {
    return SubmitTaskRequest(
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $SubmitTaskRequestCopyWith on SubmitTaskRequest {
  /// Returns a callable class that can be used as follows: `instanceOfSubmitTaskRequest.copyWith(...)` or like so:`instanceOfSubmitTaskRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubmitTaskRequestCWProxy get copyWith =>
      _$SubmitTaskRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubmitTaskRequest _$SubmitTaskRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SubmitTaskRequest', json, ($checkedConvert) {
      final val = SubmitTaskRequest(
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SubmitTaskRequestToJson(SubmitTaskRequest instance) =>
    <String, dynamic>{'note': ?instance.note};
