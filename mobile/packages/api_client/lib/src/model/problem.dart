//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/problem_errors_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'problem.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Problem {
  /// Returns a new [Problem] instance.
  Problem({
    required this.type,

    required this.title,

    required this.status,

    this.detail,

    this.instance,

    required this.code,

    this.errors,
  });

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final String type;

  /// Short, human-readable summary.
  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final int status;

  /// What went wrong and what to do, safe to show to the user.
  @JsonKey(name: r'detail', required: false, includeIfNull: false)
  final String? detail;

  @JsonKey(name: r'instance', required: false, includeIfNull: false)
  final String? instance;

  /// Machine-readable error code, `<area>.<reason>`.
  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  /// Per-field validation errors.
  @JsonKey(name: r'errors', required: false, includeIfNull: false)
  final List<ProblemErrorsInner>? errors;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Problem &&
            runtimeType == other.runtimeType &&
            equals(
              [type, title, status, detail, instance, code, errors],
              [
                other.type,
                other.title,
                other.status,
                other.detail,
                other.instance,
                other.code,
                other.errors,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([type, title, status, detail, instance, code, errors]);

  factory Problem.fromJson(Map<String, dynamic> json) =>
      _$ProblemFromJson(json);

  Map<String, dynamic> toJson() => _$ProblemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
