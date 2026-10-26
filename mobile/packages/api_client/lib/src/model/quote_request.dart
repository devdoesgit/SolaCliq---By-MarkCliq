//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/quote_estimate.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'quote_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class QuoteRequest {
  /// Returns a new [QuoteRequest] instance.
  QuoteRequest({
    required this.id,

    required this.status,

    required this.createdAt,

    required this.estimate,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final QuoteRequestStatusEnum status;

  /// ISO 8601, UTC.
  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'estimate', required: true, includeIfNull: false)
  final QuoteEstimate estimate;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuoteRequest &&
            runtimeType == other.runtimeType &&
            equals(
              [id, status, createdAt, estimate],
              [other.id, other.status, other.createdAt, other.estimate],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, status, createdAt, estimate]);

  factory QuoteRequest.fromJson(Map<String, dynamic> json) =>
      _$QuoteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$QuoteRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum QuoteRequestStatusEnum {
  @JsonValue(r'open')
  open(r'open'),
  @JsonValue(r'accepted')
  accepted(r'accepted'),
  @JsonValue(r'closed')
  closed(r'closed');

  const QuoteRequestStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
