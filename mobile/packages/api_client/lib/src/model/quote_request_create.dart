//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/bill_band.dart';
import 'package:api_client/src/model/quote_for.dart';
import 'package:api_client/src/model/quote_timeline.dart';
import 'package:api_client/src/model/roof_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'quote_request_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class QuoteRequestCreate {
  /// Returns a new [QuoteRequestCreate] instance.
  QuoteRequestCreate({
    required this.quoteFor,

    required this.pinCode,

    required this.city,

    required this.billBand,

    required this.roof,

    required this.timeline,

    this.phone,

    required this.shareConsent,
  });

  @JsonKey(name: r'quote_for', required: true, includeIfNull: false)
  final QuoteFor quoteFor;

  @JsonKey(name: r'pin_code', required: true, includeIfNull: false)
  final String pinCode;

  @JsonKey(name: r'city', required: true, includeIfNull: false)
  final String city;

  @JsonKey(name: r'bill_band', required: true, includeIfNull: false)
  final BillBand billBand;

  @JsonKey(name: r'roof', required: true, includeIfNull: false)
  final RoofType roof;

  @JsonKey(name: r'timeline', required: true, includeIfNull: false)
  final QuoteTimeline timeline;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  /// The person agrees to be contacted. Must be true; anything else is 422 `quote.consent_required`.
  @JsonKey(name: r'share_consent', required: true, includeIfNull: false)
  final bool shareConsent;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuoteRequestCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [
                quoteFor,
                pinCode,
                city,
                billBand,
                roof,
                timeline,
                phone,
                shareConsent,
              ],
              [
                other.quoteFor,
                other.pinCode,
                other.city,
                other.billBand,
                other.roof,
                other.timeline,
                other.phone,
                other.shareConsent,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        quoteFor,
        pinCode,
        city,
        billBand,
        roof,
        timeline,
        phone,
        shareConsent,
      ]);

  factory QuoteRequestCreate.fromJson(Map<String, dynamic> json) =>
      _$QuoteRequestCreateFromJson(json);

  Map<String, dynamic> toJson() => _$QuoteRequestCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
