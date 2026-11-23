//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/admin_task_problem.dart';
import 'package:api_client/src/model/proof_slot.dart';
import 'package:api_client/src/model/admin_stage.dart';
import 'package:api_client/src/model/checklist_item.dart';
import 'package:api_client/src/model/task_status.dart';
import 'package:api_client/src/model/admin_task_event.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_task.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminTask {
  /// Returns a new [AdminTask] instance.
  AdminTask({
    required this.id,

    required this.reference,

    required this.title,

    required this.status,

    required this.dueAt,

    required this.statusAt,

    required this.stage,

    required this.customerId,

    required this.customerName,

    required this.place,

    this.systemKw,

    required this.assigneeId,

    required this.assigneeName,

    required this.assigneeActive,

    required this.hasProblem,

    required this.address,

    this.phone,

    this.lat,

    this.lng,

    this.adminNote,

    this.workerNote,

    this.submittedAt,

    this.returnedNote,

    this.cancelledNote,

    this.problem,

    required this.photos,

    required this.checklist,

    required this.events,
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

  /// ISO 8601, UTC.
  @JsonKey(name: r'status_at', required: true, includeIfNull: false)
  final DateTime statusAt;

  @JsonKey(name: r'stage', required: true, includeIfNull: false)
  final AdminStage stage;

  /// UUIDv7.
  @JsonKey(name: r'customer_id', required: true, includeIfNull: false)
  final String customerId;

  @JsonKey(name: r'customer_name', required: true, includeIfNull: false)
  final String customerName;

  /// The customer's city, or their address without one.
  @JsonKey(name: r'place', required: true, includeIfNull: false)
  final String place;

  @JsonKey(name: r'system_kw', required: false, includeIfNull: false)
  final num? systemKw;

  /// UUIDv7.
  @JsonKey(name: r'assignee_id', required: true, includeIfNull: false)
  final String assigneeId;

  @JsonKey(name: r'assignee_name', required: true, includeIfNull: false)
  final String assigneeName;

  /// False once they were removed from the company.
  @JsonKey(name: r'assignee_active', required: true, includeIfNull: false)
  final bool assigneeActive;

  @JsonKey(name: r'has_problem', required: true, includeIfNull: false)
  final bool hasProblem;

  @JsonKey(name: r'address', required: true, includeIfNull: false)
  final String address;

  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  @JsonKey(name: r'lat', required: false, includeIfNull: false)
  final num? lat;

  @JsonKey(name: r'lng', required: false, includeIfNull: false)
  final num? lng;

  @JsonKey(name: r'admin_note', required: false, includeIfNull: false)
  final String? adminNote;

  @JsonKey(name: r'worker_note', required: false, includeIfNull: false)
  final String? workerNote;

  /// ISO 8601, UTC.
  @JsonKey(name: r'submitted_at', required: false, includeIfNull: false)
  final DateTime? submittedAt;

  @JsonKey(name: r'returned_note', required: false, includeIfNull: false)
  final String? returnedNote;

  @JsonKey(name: r'cancelled_note', required: false, includeIfNull: false)
  final String? cancelledNote;

  @JsonKey(name: r'problem', required: false, includeIfNull: false)
  final AdminTaskProblem? problem;

  @JsonKey(name: r'photos', required: true, includeIfNull: false)
  final List<ProofSlot> photos;

  @JsonKey(name: r'checklist', required: true, includeIfNull: false)
  final List<ChecklistItem> checklist;

  @JsonKey(name: r'events', required: true, includeIfNull: false)
  final List<AdminTaskEvent> events;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminTask &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                reference,
                title,
                status,
                dueAt,
                statusAt,
                stage,
                customerId,
                customerName,
                place,
                systemKw,
                assigneeId,
                assigneeName,
                assigneeActive,
                hasProblem,
                address,
                phone,
                lat,
                lng,
                adminNote,
                workerNote,
                submittedAt,
                returnedNote,
                cancelledNote,
                problem,
                photos,
                checklist,
                events,
              ],
              [
                other.id,
                other.reference,
                other.title,
                other.status,
                other.dueAt,
                other.statusAt,
                other.stage,
                other.customerId,
                other.customerName,
                other.place,
                other.systemKw,
                other.assigneeId,
                other.assigneeName,
                other.assigneeActive,
                other.hasProblem,
                other.address,
                other.phone,
                other.lat,
                other.lng,
                other.adminNote,
                other.workerNote,
                other.submittedAt,
                other.returnedNote,
                other.cancelledNote,
                other.problem,
                other.photos,
                other.checklist,
                other.events,
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
        statusAt,
        stage,
        customerId,
        customerName,
        place,
        systemKw,
        assigneeId,
        assigneeName,
        assigneeActive,
        hasProblem,
        address,
        phone,
        lat,
        lng,
        adminNote,
        workerNote,
        submittedAt,
        returnedNote,
        cancelledNote,
        problem,
        photos,
        checklist,
        events,
      ]);

  factory AdminTask.fromJson(Map<String, dynamic> json) =>
      _$AdminTaskFromJson(json);

  Map<String, dynamic> toJson() => _$AdminTaskToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
