// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_registration_create_documents_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerRegistrationCreateDocumentsInnerCWProxy {
  CustomerRegistrationCreateDocumentsInner kind(KycKind kind);

  CustomerRegistrationCreateDocumentsInner uploadId(String uploadId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerRegistrationCreateDocumentsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerRegistrationCreateDocumentsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerRegistrationCreateDocumentsInner call({
    KycKind kind,
    String uploadId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCustomerRegistrationCreateDocumentsInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCustomerRegistrationCreateDocumentsInner.copyWith.fieldName(...)`
class _$CustomerRegistrationCreateDocumentsInnerCWProxyImpl
    implements _$CustomerRegistrationCreateDocumentsInnerCWProxy {
  const _$CustomerRegistrationCreateDocumentsInnerCWProxyImpl(this._value);

  final CustomerRegistrationCreateDocumentsInner _value;

  @override
  CustomerRegistrationCreateDocumentsInner kind(KycKind kind) =>
      this(kind: kind);

  @override
  CustomerRegistrationCreateDocumentsInner uploadId(String uploadId) =>
      this(uploadId: uploadId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerRegistrationCreateDocumentsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerRegistrationCreateDocumentsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerRegistrationCreateDocumentsInner call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? uploadId = const $CopyWithPlaceholder(),
  }) {
    return CustomerRegistrationCreateDocumentsInner(
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as KycKind,
      uploadId: uploadId == const $CopyWithPlaceholder()
          ? _value.uploadId
          // ignore: cast_nullable_to_non_nullable
          : uploadId as String,
    );
  }
}

extension $CustomerRegistrationCreateDocumentsInnerCopyWith
    on CustomerRegistrationCreateDocumentsInner {
  /// Returns a callable class that can be used as follows: `instanceOfCustomerRegistrationCreateDocumentsInner.copyWith(...)` or like so:`instanceOfCustomerRegistrationCreateDocumentsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerRegistrationCreateDocumentsInnerCWProxy get copyWith =>
      _$CustomerRegistrationCreateDocumentsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerRegistrationCreateDocumentsInner
_$CustomerRegistrationCreateDocumentsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CustomerRegistrationCreateDocumentsInner', json, (
      $checkedConvert,
    ) {
      $checkKeys(json, requiredKeys: const ['kind', 'upload_id']);
      final val = CustomerRegistrationCreateDocumentsInner(
        kind: $checkedConvert('kind', (v) => $enumDecode(_$KycKindEnumMap, v)),
        uploadId: $checkedConvert('upload_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'uploadId': 'upload_id'});

Map<String, dynamic> _$CustomerRegistrationCreateDocumentsInnerToJson(
  CustomerRegistrationCreateDocumentsInner instance,
) => <String, dynamic>{
  'kind': _$KycKindEnumMap[instance.kind]!,
  'upload_id': instance.uploadId,
};

const _$KycKindEnumMap = {
  KycKind.aadhaar: 'aadhaar',
  KycKind.pan: 'pan',
  KycKind.electricityBill: 'electricity_bill',
  KycKind.bankProof: 'bank_proof',
  KycKind.roofPhoto: 'roof_photo',
};
