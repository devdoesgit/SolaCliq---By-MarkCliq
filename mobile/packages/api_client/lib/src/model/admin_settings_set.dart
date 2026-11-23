//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_settings_set.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminSettingsSet {
  /// Returns a new [AdminSettingsSet] instance.
  AdminSettingsSet({this.upiId});

  @JsonKey(name: r'upi_id', required: false, includeIfNull: false)
  final String? upiId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminSettingsSet &&
            runtimeType == other.runtimeType &&
            equals([upiId], [other.upiId]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([upiId]);

  factory AdminSettingsSet.fromJson(Map<String, dynamic> json) =>
      _$AdminSettingsSetFromJson(json);

  Map<String, dynamic> toJson() => _$AdminSettingsSetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
