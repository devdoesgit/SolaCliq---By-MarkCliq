//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_ref.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskRef {
  /// Returns a new [TaskRef] instance.
  TaskRef({required this.id, required this.title, required this.customerName});

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'customer_name', required: true, includeIfNull: false)
  final String customerName;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskRef &&
            runtimeType == other.runtimeType &&
            equals(
              [id, title, customerName],
              [other.id, other.title, other.customerName],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([id, title, customerName]);

  factory TaskRef.fromJson(Map<String, dynamic> json) =>
      _$TaskRefFromJson(json);

  Map<String, dynamic> toJson() => _$TaskRefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
