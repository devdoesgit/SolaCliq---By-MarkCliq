// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replace_expense_receipt_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReplaceExpenseReceiptRequestCWProxy {
  ReplaceExpenseReceiptRequest uploadId(String uploadId);

  ReplaceExpenseReceiptRequest note(String? note);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReplaceExpenseReceiptRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReplaceExpenseReceiptRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ReplaceExpenseReceiptRequest call({String uploadId, String? note});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReplaceExpenseReceiptRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReplaceExpenseReceiptRequest.copyWith.fieldName(...)`
class _$ReplaceExpenseReceiptRequestCWProxyImpl
    implements _$ReplaceExpenseReceiptRequestCWProxy {
  const _$ReplaceExpenseReceiptRequestCWProxyImpl(this._value);

  final ReplaceExpenseReceiptRequest _value;

  @override
  ReplaceExpenseReceiptRequest uploadId(String uploadId) =>
      this(uploadId: uploadId);

  @override
  ReplaceExpenseReceiptRequest note(String? note) => this(note: note);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReplaceExpenseReceiptRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReplaceExpenseReceiptRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ReplaceExpenseReceiptRequest call({
    Object? uploadId = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return ReplaceExpenseReceiptRequest(
      uploadId: uploadId == const $CopyWithPlaceholder()
          ? _value.uploadId
          // ignore: cast_nullable_to_non_nullable
          : uploadId as String,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $ReplaceExpenseReceiptRequestCopyWith
    on ReplaceExpenseReceiptRequest {
  /// Returns a callable class that can be used as follows: `instanceOfReplaceExpenseReceiptRequest.copyWith(...)` or like so:`instanceOfReplaceExpenseReceiptRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReplaceExpenseReceiptRequestCWProxy get copyWith =>
      _$ReplaceExpenseReceiptRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplaceExpenseReceiptRequest _$ReplaceExpenseReceiptRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReplaceExpenseReceiptRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['upload_id']);
  final val = ReplaceExpenseReceiptRequest(
    uploadId: $checkedConvert('upload_id', (v) => v as String),
    note: $checkedConvert('note', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'uploadId': 'upload_id'});

Map<String, dynamic> _$ReplaceExpenseReceiptRequestToJson(
  ReplaceExpenseReceiptRequest instance,
) => <String, dynamic>{'upload_id': instance.uploadId, 'note': ?instance.note};
