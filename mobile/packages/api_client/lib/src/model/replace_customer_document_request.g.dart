// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replace_customer_document_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReplaceCustomerDocumentRequestCWProxy {
  ReplaceCustomerDocumentRequest uploadId(String uploadId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReplaceCustomerDocumentRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReplaceCustomerDocumentRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ReplaceCustomerDocumentRequest call({String uploadId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReplaceCustomerDocumentRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReplaceCustomerDocumentRequest.copyWith.fieldName(...)`
class _$ReplaceCustomerDocumentRequestCWProxyImpl
    implements _$ReplaceCustomerDocumentRequestCWProxy {
  const _$ReplaceCustomerDocumentRequestCWProxyImpl(this._value);

  final ReplaceCustomerDocumentRequest _value;

  @override
  ReplaceCustomerDocumentRequest uploadId(String uploadId) =>
      this(uploadId: uploadId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReplaceCustomerDocumentRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReplaceCustomerDocumentRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ReplaceCustomerDocumentRequest call({
    Object? uploadId = const $CopyWithPlaceholder(),
  }) {
    return ReplaceCustomerDocumentRequest(
      uploadId: uploadId == const $CopyWithPlaceholder()
          ? _value.uploadId
          // ignore: cast_nullable_to_non_nullable
          : uploadId as String,
    );
  }
}

extension $ReplaceCustomerDocumentRequestCopyWith
    on ReplaceCustomerDocumentRequest {
  /// Returns a callable class that can be used as follows: `instanceOfReplaceCustomerDocumentRequest.copyWith(...)` or like so:`instanceOfReplaceCustomerDocumentRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReplaceCustomerDocumentRequestCWProxy get copyWith =>
      _$ReplaceCustomerDocumentRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplaceCustomerDocumentRequest _$ReplaceCustomerDocumentRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReplaceCustomerDocumentRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['upload_id']);
  final val = ReplaceCustomerDocumentRequest(
    uploadId: $checkedConvert('upload_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'uploadId': 'upload_id'});

Map<String, dynamic> _$ReplaceCustomerDocumentRequestToJson(
  ReplaceCustomerDocumentRequest instance,
) => <String, dynamic>{'upload_id': instance.uploadId};
