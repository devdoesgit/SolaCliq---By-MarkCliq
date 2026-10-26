//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'send_task_message_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SendTaskMessageRequest {
  /// Returns a new [SendTaskMessageRequest] instance.
  SendTaskMessageRequest({required this.text});

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SendTaskMessageRequest &&
            runtimeType == other.runtimeType &&
            equals([text], [other.text]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([text]);

  factory SendTaskMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendTaskMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendTaskMessageRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
