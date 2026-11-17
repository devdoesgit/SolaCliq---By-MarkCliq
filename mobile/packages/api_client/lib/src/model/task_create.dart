//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/slot_create.dart';
import 'package:api_client/src/model/checklist_create.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskCreate {
  /// Returns a new [TaskCreate] instance.
  TaskCreate({
    this.adminNote,

    required this.assigneeId,

    this.checklist,

    required this.customerId,

    required this.dueAt,

    this.photos,

    required this.stageIndex,

    required this.title,
  });

  @JsonKey(name: r'admin_note', required: false, includeIfNull: false)
  final String? adminNote;

  @JsonKey(name: r'assignee_id', required: true, includeIfNull: false)
  final String assigneeId;

  @JsonKey(name: r'checklist', required: false, includeIfNull: false)
  final List<ChecklistCreate>? checklist;

  @JsonKey(name: r'customer_id', required: true, includeIfNull: false)
  final String customerId;

  @JsonKey(name: r'due_at', required: true, includeIfNull: false)
  final DateTime dueAt;

  @JsonKey(name: r'photos', required: false, includeIfNull: false)
  final List<SlotCreate>? photos;

  @JsonKey(name: r'stage_index', required: true, includeIfNull: false)
  final int stageIndex;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [
                adminNote,
                assigneeId,
                checklist,
                customerId,
                dueAt,
                photos,
                stageIndex,
                title,
              ],
              [
                other.adminNote,
                other.assigneeId,
                other.checklist,
                other.customerId,
                other.dueAt,
                other.photos,
                other.stageIndex,
                other.title,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        adminNote,
        assigneeId,
        checklist,
        customerId,
        dueAt,
        photos,
        stageIndex,
        title,
      ]);

  factory TaskCreate.fromJson(Map<String, dynamic> json) =>
      _$TaskCreateFromJson(json);

  Map<String, dynamic> toJson() => _$TaskCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
