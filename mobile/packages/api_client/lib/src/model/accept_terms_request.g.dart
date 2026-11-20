// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_terms_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AcceptTermsRequestCWProxy {
  AcceptTermsRequest version(int version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AcceptTermsRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AcceptTermsRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AcceptTermsRequest call({int version});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAcceptTermsRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAcceptTermsRequest.copyWith.fieldName(...)`
class _$AcceptTermsRequestCWProxyImpl implements _$AcceptTermsRequestCWProxy {
  const _$AcceptTermsRequestCWProxyImpl(this._value);

  final AcceptTermsRequest _value;

  @override
  AcceptTermsRequest version(int version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AcceptTermsRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AcceptTermsRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AcceptTermsRequest call({Object? version = const $CopyWithPlaceholder()}) {
    return AcceptTermsRequest(
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
    );
  }
}

extension $AcceptTermsRequestCopyWith on AcceptTermsRequest {
  /// Returns a callable class that can be used as follows: `instanceOfAcceptTermsRequest.copyWith(...)` or like so:`instanceOfAcceptTermsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AcceptTermsRequestCWProxy get copyWith =>
      _$AcceptTermsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptTermsRequest _$AcceptTermsRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AcceptTermsRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['version']);
      final val = AcceptTermsRequest(
        version: $checkedConvert('version', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$AcceptTermsRequestToJson(AcceptTermsRequest instance) =>
    <String, dynamic>{'version': instance.version};
