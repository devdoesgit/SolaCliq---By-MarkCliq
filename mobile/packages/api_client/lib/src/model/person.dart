//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'person.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Person {
  /// Returns a new [Person] instance.
  Person({required this.name, this.role, this.you = false});

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  /// Shown after the name, e.g. \"Admin\".
  @JsonKey(name: r'role', required: false, includeIfNull: false)
  final String? role;

  /// The caller.
  @JsonKey(
    defaultValue: false,
    name: r'you',
    required: false,
    includeIfNull: false,
  )
  final bool? you;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Person &&
            runtimeType == other.runtimeType &&
            equals([name, role, you], [other.name, other.role, other.you]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([name, role, you]);

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

  Map<String, dynamic> toJson() => _$PersonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
