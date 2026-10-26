//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/task_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskSummary {
  /// Returns a new [TaskSummary] instance.
  TaskSummary({
    required this.id,

    required this.reference,

    required this.title,

    required this.status,

    required this.dueAt,

    required this.customerName,

    this.image,

    this.distanceKm,

    this.statusAt,

    this.hasProblem = false,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'reference', required: true, includeIfNull: false)
  final String reference;

  /// The work, e.g. \"Panel installation\".
  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final TaskStatus status;

  /// ISO 8601, UTC.
  @JsonKey(name: r'due_at', required: true, includeIfNull: false)
  final DateTime dueAt;

  @JsonKey(name: r'customer_name', required: true, includeIfNull: false)
  final String customerName;

  /// A picture for the row; `asset:<name>` in sample data.
  @JsonKey(name: r'image', required: false, includeIfNull: false)
  final String? image;

  /// From the caller's last known position, when known.
  @JsonKey(name: r'distance_km', required: false, includeIfNull: false)
  final num? distanceKm;

  /// When the status last changed.
  @JsonKey(name: r'status_at', required: false, includeIfNull: false)
  final DateTime? statusAt;

  @JsonKey(
    defaultValue: false,
    name: r'has_problem',
    required: false,
    includeIfNull: false,
  )
  final bool? hasProblem;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskSummary &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                reference,
                title,
                status,
                dueAt,
                customerName,
                image,
                distanceKm,
                statusAt,
                hasProblem,
              ],
              [
                other.id,
                other.reference,
                other.title,
                other.status,
                other.dueAt,
                other.customerName,
                other.image,
                other.distanceKm,
                other.statusAt,
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
        customerName,
        image,
        distanceKm,
        statusAt,
        hasProblem,
      ]);

  factory TaskSummary.fromJson(Map<String, dynamic> json) =>
      _$TaskSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$TaskSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
