//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'accept_terms_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AcceptTermsRequest {
  /// Returns a new [AcceptTermsRequest] instance.
  AcceptTermsRequest({required this.version});

  /// Must be the current version; anything else is 422 `terms.required`.
  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final int version;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AcceptTermsRequest &&
            runtimeType == other.runtimeType &&
            equals([version], [other.version]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([version]);

  factory AcceptTermsRequest.fromJson(Map<String, dynamic> json) =>
      _$AcceptTermsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AcceptTermsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
