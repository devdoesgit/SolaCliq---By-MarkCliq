// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_detail_documents.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerDetailDocumentsCWProxy {
  CustomerDetailDocuments status(DocumentStatus status);

  CustomerDetailDocuments detail(String detail);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerDetailDocuments(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerDetailDocuments(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerDetailDocuments call({DocumentStatus status, String detail});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCustomerDetailDocuments.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCustomerDetailDocuments.copyWith.fieldName(...)`
class _$CustomerDetailDocumentsCWProxyImpl
    implements _$CustomerDetailDocumentsCWProxy {
  const _$CustomerDetailDocumentsCWProxyImpl(this._value);

  final CustomerDetailDocuments _value;

  @override
  CustomerDetailDocuments status(DocumentStatus status) => this(status: status);

  @override
  CustomerDetailDocuments detail(String detail) => this(detail: detail);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerDetailDocuments(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerDetailDocuments(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerDetailDocuments call({
    Object? status = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
  }) {
    return CustomerDetailDocuments(
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as DocumentStatus,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String,
    );
  }
}

extension $CustomerDetailDocumentsCopyWith on CustomerDetailDocuments {
  /// Returns a callable class that can be used as follows: `instanceOfCustomerDetailDocuments.copyWith(...)` or like so:`instanceOfCustomerDetailDocuments.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerDetailDocumentsCWProxy get copyWith =>
      _$CustomerDetailDocumentsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerDetailDocuments _$CustomerDetailDocumentsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CustomerDetailDocuments', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['status', 'detail']);
  final val = CustomerDetailDocuments(
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$DocumentStatusEnumMap, v),
    ),
    detail: $checkedConvert('detail', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$CustomerDetailDocumentsToJson(
  CustomerDetailDocuments instance,
) => <String, dynamic>{
  'status': _$DocumentStatusEnumMap[instance.status]!,
  'detail': instance.detail,
};

const _$DocumentStatusEnumMap = {
  DocumentStatus.verified: 'verified',
  DocumentStatus.inReview: 'in_review',
  DocumentStatus.needsFix: 'needs_fix',
};
