//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_settings.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminSettings {
  /// Returns a new [AdminSettings] instance.
  AdminSettings({this.upiId, required this.stages});

  @JsonKey(name: r'upi_id', required: false, includeIfNull: false)
  final String? upiId;

  /// The install stages, in order.
  @JsonKey(name: r'stages', required: true, includeIfNull: false)
  final List<String> stages;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminSettings &&
            runtimeType == other.runtimeType &&
            equals([upiId, stages], [other.upiId, other.stages]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([upiId, stages]);

  factory AdminSettings.fromJson(Map<String, dynamic> json) =>
      _$AdminSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AdminSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
