//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'done.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Done {
  /// Returns a new [Done] instance.
  Done({required this.id, this.reference});

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'reference', required: false, includeIfNull: false)
  final String? reference;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Done &&
            runtimeType == other.runtimeType &&
            equals([id, reference], [other.id, other.reference]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([id, reference]);

  factory Done.fromJson(Map<String, dynamic> json) => _$DoneFromJson(json);

  Map<String, dynamic> toJson() => _$DoneToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
