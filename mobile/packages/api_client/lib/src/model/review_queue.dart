//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/review_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'review_queue.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReviewQueue {
  /// Returns a new [ReviewQueue] instance.
  ReviewQueue({
    required this.commissions,

    required this.expenses,

    required this.payments,

    required this.registrations,

    required this.tasks,
  });

  @JsonKey(name: r'commissions', required: true, includeIfNull: false)
  final List<ReviewItem> commissions;

  @JsonKey(name: r'expenses', required: true, includeIfNull: false)
  final List<ReviewItem> expenses;

  @JsonKey(name: r'payments', required: true, includeIfNull: false)
  final List<ReviewItem> payments;

  @JsonKey(name: r'registrations', required: true, includeIfNull: false)
  final List<ReviewItem> registrations;

  @JsonKey(name: r'tasks', required: true, includeIfNull: false)
  final List<ReviewItem> tasks;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReviewQueue &&
            runtimeType == other.runtimeType &&
            equals(
              [commissions, expenses, payments, registrations, tasks],
              [
                other.commissions,
                other.expenses,
                other.payments,
                other.registrations,
                other.tasks,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        commissions,
        expenses,
        payments,
        registrations,
        tasks,
      ]);

  factory ReviewQueue.fromJson(Map<String, dynamic> json) =>
      _$ReviewQueueFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewQueueToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
