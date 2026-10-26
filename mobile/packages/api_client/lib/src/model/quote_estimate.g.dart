// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_estimate.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$QuoteEstimateCWProxy {
  QuoteEstimate kwMin(num kwMin);

  QuoteEstimate kwMax(num kwMax);

  QuoteEstimate priceMin(int priceMin);

  QuoteEstimate priceMax(int priceMax);

  QuoteEstimate subsidyMax(int subsidyMax);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuoteEstimate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuoteEstimate(...).copyWith(id: 12, name: "My name")
  /// ````
  QuoteEstimate call({
    num kwMin,
    num kwMax,
    int priceMin,
    int priceMax,
    int subsidyMax,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQuoteEstimate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQuoteEstimate.copyWith.fieldName(...)`
class _$QuoteEstimateCWProxyImpl implements _$QuoteEstimateCWProxy {
  const _$QuoteEstimateCWProxyImpl(this._value);

  final QuoteEstimate _value;

  @override
  QuoteEstimate kwMin(num kwMin) => this(kwMin: kwMin);

  @override
  QuoteEstimate kwMax(num kwMax) => this(kwMax: kwMax);

  @override
  QuoteEstimate priceMin(int priceMin) => this(priceMin: priceMin);

  @override
  QuoteEstimate priceMax(int priceMax) => this(priceMax: priceMax);

  @override
  QuoteEstimate subsidyMax(int subsidyMax) => this(subsidyMax: subsidyMax);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuoteEstimate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuoteEstimate(...).copyWith(id: 12, name: "My name")
  /// ````
  QuoteEstimate call({
    Object? kwMin = const $CopyWithPlaceholder(),
    Object? kwMax = const $CopyWithPlaceholder(),
    Object? priceMin = const $CopyWithPlaceholder(),
    Object? priceMax = const $CopyWithPlaceholder(),
    Object? subsidyMax = const $CopyWithPlaceholder(),
  }) {
    return QuoteEstimate(
      kwMin: kwMin == const $CopyWithPlaceholder()
          ? _value.kwMin
          // ignore: cast_nullable_to_non_nullable
          : kwMin as num,
      kwMax: kwMax == const $CopyWithPlaceholder()
          ? _value.kwMax
          // ignore: cast_nullable_to_non_nullable
          : kwMax as num,
      priceMin: priceMin == const $CopyWithPlaceholder()
          ? _value.priceMin
          // ignore: cast_nullable_to_non_nullable
          : priceMin as int,
      priceMax: priceMax == const $CopyWithPlaceholder()
          ? _value.priceMax
          // ignore: cast_nullable_to_non_nullable
          : priceMax as int,
      subsidyMax: subsidyMax == const $CopyWithPlaceholder()
          ? _value.subsidyMax
          // ignore: cast_nullable_to_non_nullable
          : subsidyMax as int,
    );
  }
}

extension $QuoteEstimateCopyWith on QuoteEstimate {
  /// Returns a callable class that can be used as follows: `instanceOfQuoteEstimate.copyWith(...)` or like so:`instanceOfQuoteEstimate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$QuoteEstimateCWProxy get copyWith => _$QuoteEstimateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuoteEstimate _$QuoteEstimateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'QuoteEstimate',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'kw_min',
            'kw_max',
            'price_min',
            'price_max',
            'subsidy_max',
          ],
        );
        final val = QuoteEstimate(
          kwMin: $checkedConvert('kw_min', (v) => v as num),
          kwMax: $checkedConvert('kw_max', (v) => v as num),
          priceMin: $checkedConvert('price_min', (v) => (v as num).toInt()),
          priceMax: $checkedConvert('price_max', (v) => (v as num).toInt()),
          subsidyMax: $checkedConvert('subsidy_max', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'kwMin': 'kw_min',
        'kwMax': 'kw_max',
        'priceMin': 'price_min',
        'priceMax': 'price_max',
        'subsidyMax': 'subsidy_max',
      },
    );

Map<String, dynamic> _$QuoteEstimateToJson(QuoteEstimate instance) =>
    <String, dynamic>{
      'kw_min': instance.kwMin,
      'kw_max': instance.kwMax,
      'price_min': instance.priceMin,
      'price_max': instance.priceMax,
      'subsidy_max': instance.subsidyMax,
    };
