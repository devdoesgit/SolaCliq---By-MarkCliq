//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'logo_set.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LogoSet {
  /// Returns a new [LogoSet] instance.
  LogoSet({required this.uploadId});

  /// UUIDv7.
  @JsonKey(name: r'upload_id', required: true, includeIfNull: false)
  final String uploadId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LogoSet &&
            runtimeType == other.runtimeType &&
            equals([uploadId], [other.uploadId]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([uploadId]);

  factory LogoSet.fromJson(Map<String, dynamic> json) =>
      _$LogoSetFromJson(json);

  Map<String, dynamic> toJson() => _$LogoSetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
