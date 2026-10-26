//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/task_note.dart';
import 'package:api_client/src/model/task_stage.dart';
import 'package:api_client/src/model/person.dart';
import 'package:api_client/src/model/proof_slot.dart';
import 'package:api_client/src/model/checklist_item.dart';
import 'package:api_client/src/model/task_status.dart';
import 'package:api_client/src/model/task_approved.dart';
import 'package:api_client/src/model/task_customer.dart';
import 'package:api_client/src/model/task_problem.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Task {
  /// Returns a new [Task] instance.
  Task({
    required this.id,

    required this.reference,

    required this.title,

    required this.status,

    required this.dueAt,

    required this.stage,

    this.assignedBy,

    required this.customer,

    this.adminNote,

    required this.photos,

    required this.checklist,

    this.submittedAt,

    this.workerNote,

    this.returned,

    this.problem,

    this.cancelled,

    this.approved,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'reference', required: true, includeIfNull: false)
  final String reference;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final TaskStatus status;

  /// ISO 8601, UTC.
  @JsonKey(name: r'due_at', required: true, includeIfNull: false)
  final DateTime dueAt;

  @JsonKey(name: r'stage', required: true, includeIfNull: false)
  final TaskStage stage;

  @JsonKey(name: r'assigned_by', required: false, includeIfNull: false)
  final Person? assignedBy;

  @JsonKey(name: r'customer', required: true, includeIfNull: false)
  final TaskCustomer customer;

  @JsonKey(name: r'admin_note', required: false, includeIfNull: false)
  final TaskNote? adminNote;

  @JsonKey(name: r'photos', required: true, includeIfNull: false)
  final List<ProofSlot> photos;

  @JsonKey(name: r'checklist', required: true, includeIfNull: false)
  final List<ChecklistItem> checklist;

  /// ISO 8601, UTC.
  @JsonKey(name: r'submitted_at', required: false, includeIfNull: false)
  final DateTime? submittedAt;

  @JsonKey(name: r'worker_note', required: false, includeIfNull: false)
  final String? workerNote;

  /// Why the admin sent it back.
  @JsonKey(name: r'returned', required: false, includeIfNull: false)
  final TaskNote? returned;

  /// An open problem the caller reported.
  @JsonKey(name: r'problem', required: false, includeIfNull: false)
  final TaskProblem? problem;

  @JsonKey(name: r'cancelled', required: false, includeIfNull: false)
  final TaskNote? cancelled;

  @JsonKey(name: r'approved', required: false, includeIfNull: false)
  final TaskApproved? approved;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Task &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                reference,
                title,
                status,
                dueAt,
                stage,
                assignedBy,
                customer,
                adminNote,
                photos,
                checklist,
                submittedAt,
                workerNote,
                returned,
                problem,
                cancelled,
                approved,
              ],
              [
                other.id,
                other.reference,
                other.title,
                other.status,
                other.dueAt,
                other.stage,
                other.assignedBy,
                other.customer,
                other.adminNote,
                other.photos,
                other.checklist,
                other.submittedAt,
                other.workerNote,
                other.returned,
                other.problem,
                other.cancelled,
                other.approved,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        reference,
        title,
        status,
        dueAt,
        stage,
        assignedBy,
        customer,
        adminNote,
        photos,
        checklist,
        submittedAt,
        workerNote,
        returned,
        problem,
        cancelled,
        approved,
      ]);

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
