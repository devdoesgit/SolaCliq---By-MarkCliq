//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_detail_stage.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerDetailStage {
  /// Returns a new [CustomerDetailStage] instance.
  CustomerDetailStage({
    required this.index,

    required this.count,

    required this.label,
  });

  @JsonKey(name: r'index', required: true, includeIfNull: false)
  final int index;

  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerDetailStage &&
            runtimeType == other.runtimeType &&
            equals(
              [index, count, label],
              [other.index, other.count, other.label],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([index, count, label]);

  factory CustomerDetailStage.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailStageFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDetailStageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
