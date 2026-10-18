//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'email_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EmailRequest {
  /// Returns a new [EmailRequest] instance.
  EmailRequest({required this.email});

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EmailRequest &&
            runtimeType == other.runtimeType &&
            equals([email], [other.email]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([email]);

  factory EmailRequest.fromJson(Map<String, dynamic> json) =>
      _$EmailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EmailRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
