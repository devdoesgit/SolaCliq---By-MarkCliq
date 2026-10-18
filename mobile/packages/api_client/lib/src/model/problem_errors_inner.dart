//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'problem_errors_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProblemErrorsInner {
  /// Returns a new [ProblemErrorsInner] instance.
  ProblemErrorsInner({required this.field, required this.message});

  @JsonKey(name: r'field', required: true, includeIfNull: false)
  final String field;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProblemErrorsInner &&
            runtimeType == other.runtimeType &&
            equals([field, message], [other.field, other.message]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([field, message]);

  factory ProblemErrorsInner.fromJson(Map<String, dynamic> json) =>
      _$ProblemErrorsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ProblemErrorsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
