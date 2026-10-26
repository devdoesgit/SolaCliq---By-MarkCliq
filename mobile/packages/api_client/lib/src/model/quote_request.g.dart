// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$QuoteRequestCWProxy {
  QuoteRequest id(String id);

  QuoteRequest status(QuoteRequestStatusEnum status);

  QuoteRequest createdAt(DateTime createdAt);

  QuoteRequest estimate(QuoteEstimate estimate);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuoteRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuoteRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  QuoteRequest call({
    String id,
    QuoteRequestStatusEnum status,
    DateTime createdAt,
    QuoteEstimate estimate,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQuoteRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQuoteRequest.copyWith.fieldName(...)`
class _$QuoteRequestCWProxyImpl implements _$QuoteRequestCWProxy {
  const _$QuoteRequestCWProxyImpl(this._value);

  final QuoteRequest _value;

  @override
  QuoteRequest id(String id) => this(id: id);

  @override
  QuoteRequest status(QuoteRequestStatusEnum status) => this(status: status);

  @override
  QuoteRequest createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  QuoteRequest estimate(QuoteEstimate estimate) => this(estimate: estimate);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuoteRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuoteRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  QuoteRequest call({
    Object? id = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? estimate = const $CopyWithPlaceholder(),
  }) {
    return QuoteRequest(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as QuoteRequestStatusEnum,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      estimate: estimate == const $CopyWithPlaceholder()
          ? _value.estimate
          // ignore: cast_nullable_to_non_nullable
          : estimate as QuoteEstimate,
    );
  }
}

extension $QuoteRequestCopyWith on QuoteRequest {
  /// Returns a callable class that can be used as follows: `instanceOfQuoteRequest.copyWith(...)` or like so:`instanceOfQuoteRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$QuoteRequestCWProxy get copyWith => _$QuoteRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuoteRequest _$QuoteRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('QuoteRequest', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'status', 'created_at', 'estimate'],
      );
      final val = QuoteRequest(
        id: $checkedConvert('id', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$QuoteRequestStatusEnumEnumMap, v),
        ),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
        estimate: $checkedConvert(
          'estimate',
          (v) => QuoteEstimate.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'createdAt': 'created_at'});

Map<String, dynamic> _$QuoteRequestToJson(QuoteRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$QuoteRequestStatusEnumEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'estimate': instance.estimate.toJson(),
    };

const _$QuoteRequestStatusEnumEnumMap = {
  QuoteRequestStatusEnum.open: 'open',
  QuoteRequestStatusEnum.accepted: 'accepted',
  QuoteRequestStatusEnum.closed: 'closed',
};
