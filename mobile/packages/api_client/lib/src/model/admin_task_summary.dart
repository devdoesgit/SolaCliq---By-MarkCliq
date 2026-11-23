//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/admin_stage.dart';
import 'package:api_client/src/model/task_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_task_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminTaskSummary {
  /// Returns a new [AdminTaskSummary] instance.
  AdminTaskSummary({
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

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminTaskSummary &&
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
      ]);

  factory AdminTaskSummary.fromJson(Map<String, dynamic> json) =>
      _$AdminTaskSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$AdminTaskSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
