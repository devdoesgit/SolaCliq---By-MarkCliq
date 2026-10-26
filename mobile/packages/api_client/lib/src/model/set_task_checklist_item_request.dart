//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'set_task_checklist_item_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetTaskChecklistItemRequest {
  /// Returns a new [SetTaskChecklistItemRequest] instance.
  SetTaskChecklistItemRequest({required this.done});

  @JsonKey(name: r'done', required: true, includeIfNull: false)
  final bool done;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SetTaskChecklistItemRequest &&
            runtimeType == other.runtimeType &&
            equals([done], [other.done]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([done]);

  factory SetTaskChecklistItemRequest.fromJson(Map<String, dynamic> json) =>
      _$SetTaskChecklistItemRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetTaskChecklistItemRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
