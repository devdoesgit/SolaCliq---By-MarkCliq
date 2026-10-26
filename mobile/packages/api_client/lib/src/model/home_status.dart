//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/home_tone.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_status.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeStatus {
  /// Returns a new [HomeStatus] instance.
  HomeStatus({required this.label, required this.tone});

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'tone', required: true, includeIfNull: false)
  final HomeTone tone;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeStatus &&
            runtimeType == other.runtimeType &&
            equals([label, tone], [other.label, other.tone]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([label, tone]);

  factory HomeStatus.fromJson(Map<String, dynamic> json) =>
      _$HomeStatusFromJson(json);

  Map<String, dynamic> toJson() => _$HomeStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
