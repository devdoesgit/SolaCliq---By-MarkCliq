//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'install_next_visit_person.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InstallNextVisitPerson {
  /// Returns a new [InstallNextVisitPerson] instance.
  InstallNextVisitPerson({required this.name, this.phone});

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InstallNextVisitPerson &&
            runtimeType == other.runtimeType &&
            equals([name, phone], [other.name, other.phone]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([name, phone]);

  factory InstallNextVisitPerson.fromJson(Map<String, dynamic> json) =>
      _$InstallNextVisitPersonFromJson(json);

  Map<String, dynamic> toJson() => _$InstallNextVisitPersonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
