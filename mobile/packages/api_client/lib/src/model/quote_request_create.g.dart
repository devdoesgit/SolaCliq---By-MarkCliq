// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_request_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$QuoteRequestCreateCWProxy {
  QuoteRequestCreate quoteFor(QuoteFor quoteFor);

  QuoteRequestCreate pinCode(String pinCode);

  QuoteRequestCreate city(String city);

  QuoteRequestCreate billBand(BillBand billBand);

  QuoteRequestCreate roof(RoofType roof);

  QuoteRequestCreate timeline(QuoteTimeline timeline);

  QuoteRequestCreate phone(String? phone);

  QuoteRequestCreate shareConsent(bool shareConsent);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuoteRequestCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuoteRequestCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  QuoteRequestCreate call({
    QuoteFor quoteFor,
    String pinCode,
    String city,
    BillBand billBand,
    RoofType roof,
    QuoteTimeline timeline,
    String? phone,
    bool shareConsent,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQuoteRequestCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQuoteRequestCreate.copyWith.fieldName(...)`
class _$QuoteRequestCreateCWProxyImpl implements _$QuoteRequestCreateCWProxy {
  const _$QuoteRequestCreateCWProxyImpl(this._value);

  final QuoteRequestCreate _value;

  @override
  QuoteRequestCreate quoteFor(QuoteFor quoteFor) => this(quoteFor: quoteFor);

  @override
  QuoteRequestCreate pinCode(String pinCode) => this(pinCode: pinCode);

  @override
  QuoteRequestCreate city(String city) => this(city: city);

  @override
  QuoteRequestCreate billBand(BillBand billBand) => this(billBand: billBand);

  @override
  QuoteRequestCreate roof(RoofType roof) => this(roof: roof);

  @override
  QuoteRequestCreate timeline(QuoteTimeline timeline) =>
      this(timeline: timeline);

  @override
  QuoteRequestCreate phone(String? phone) => this(phone: phone);

  @override
  QuoteRequestCreate shareConsent(bool shareConsent) =>
      this(shareConsent: shareConsent);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `QuoteRequestCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// QuoteRequestCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  QuoteRequestCreate call({
    Object? quoteFor = const $CopyWithPlaceholder(),
    Object? pinCode = const $CopyWithPlaceholder(),
    Object? city = const $CopyWithPlaceholder(),
    Object? billBand = const $CopyWithPlaceholder(),
    Object? roof = const $CopyWithPlaceholder(),
    Object? timeline = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? shareConsent = const $CopyWithPlaceholder(),
  }) {
    return QuoteRequestCreate(
      quoteFor: quoteFor == const $CopyWithPlaceholder()
          ? _value.quoteFor
          // ignore: cast_nullable_to_non_nullable
          : quoteFor as QuoteFor,
      pinCode: pinCode == const $CopyWithPlaceholder()
          ? _value.pinCode
          // ignore: cast_nullable_to_non_nullable
          : pinCode as String,
      city: city == const $CopyWithPlaceholder()
          ? _value.city
          // ignore: cast_nullable_to_non_nullable
          : city as String,
      billBand: billBand == const $CopyWithPlaceholder()
          ? _value.billBand
          // ignore: cast_nullable_to_non_nullable
          : billBand as BillBand,
      roof: roof == const $CopyWithPlaceholder()
          ? _value.roof
          // ignore: cast_nullable_to_non_nullable
          : roof as RoofType,
      timeline: timeline == const $CopyWithPlaceholder()
          ? _value.timeline
          // ignore: cast_nullable_to_non_nullable
          : timeline as QuoteTimeline,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
      shareConsent: shareConsent == const $CopyWithPlaceholder()
          ? _value.shareConsent
          // ignore: cast_nullable_to_non_nullable
          : shareConsent as bool,
    );
  }
}

extension $QuoteRequestCreateCopyWith on QuoteRequestCreate {
  /// Returns a callable class that can be used as follows: `instanceOfQuoteRequestCreate.copyWith(...)` or like so:`instanceOfQuoteRequestCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$QuoteRequestCreateCWProxy get copyWith =>
      _$QuoteRequestCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuoteRequestCreate _$QuoteRequestCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'QuoteRequestCreate',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'quote_for',
            'pin_code',
            'city',
            'bill_band',
            'roof',
            'timeline',
            'share_consent',
          ],
        );
        final val = QuoteRequestCreate(
          quoteFor: $checkedConvert(
            'quote_for',
            (v) => $enumDecode(_$QuoteForEnumMap, v),
          ),
          pinCode: $checkedConvert('pin_code', (v) => v as String),
          city: $checkedConvert('city', (v) => v as String),
          billBand: $checkedConvert(
            'bill_band',
            (v) => $enumDecode(_$BillBandEnumMap, v),
          ),
          roof: $checkedConvert(
            'roof',
            (v) => $enumDecode(_$RoofTypeEnumMap, v),
          ),
          timeline: $checkedConvert(
            'timeline',
            (v) => $enumDecode(_$QuoteTimelineEnumMap, v),
          ),
          phone: $checkedConvert('phone', (v) => v as String?),
          shareConsent: $checkedConvert('share_consent', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'quoteFor': 'quote_for',
        'pinCode': 'pin_code',
        'billBand': 'bill_band',
        'shareConsent': 'share_consent',
      },
    );

Map<String, dynamic> _$QuoteRequestCreateToJson(QuoteRequestCreate instance) =>
    <String, dynamic>{
      'quote_for': _$QuoteForEnumMap[instance.quoteFor]!,
      'pin_code': instance.pinCode,
      'city': instance.city,
      'bill_band': _$BillBandEnumMap[instance.billBand]!,
      'roof': _$RoofTypeEnumMap[instance.roof]!,
      'timeline': _$QuoteTimelineEnumMap[instance.timeline]!,
      'phone': ?instance.phone,
      'share_consent': instance.shareConsent,
    };

const _$QuoteForEnumMap = {
  QuoteFor.home: 'home',
  QuoteFor.business: 'business',
  QuoteFor.farm: 'farm',
};

const _$BillBandEnumMap = {
  BillBand.under1500: 'under_1500',
  BillBand.from1500To3000: 'from_1500_to_3000',
  BillBand.from3000To6000: 'from_3000_to_6000',
  BillBand.over6000: 'over_6000',
};

const _$RoofTypeEnumMap = {
  RoofType.rcc: 'rcc',
  RoofType.tinShed: 'tin_shed',
  RoofType.other: 'other',
};

const _$QuoteTimelineEnumMap = {
  QuoteTimeline.thisMonth: 'this_month',
  QuoteTimeline.in1To3Months: 'in_1_to_3_months',
  QuoteTimeline.exploring: 'exploring',
};
