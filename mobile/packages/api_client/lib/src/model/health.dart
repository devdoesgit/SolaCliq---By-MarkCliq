//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'health.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Health {
  /// Returns a new [Health] instance.
  Health({required this.status, required this.version, required this.database});

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final HealthStatusEnum status;

  /// Backend build version.
  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final String version;

  @JsonKey(name: r'database', required: true, includeIfNull: false)
  final HealthDatabaseEnum database;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Health &&
            runtimeType == other.runtimeType &&
            equals(
              [status, version, database],
              [other.status, other.version, other.database],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([status, version, database]);

  factory Health.fromJson(Map<String, dynamic> json) => _$HealthFromJson(json);

  Map<String, dynamic> toJson() => _$HealthToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HealthStatusEnum {
  @JsonValue(r'ok')
  ok(r'ok'),
  @JsonValue(r'degraded')
  degraded(r'degraded');

  const HealthStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum HealthDatabaseEnum {
  @JsonValue(r'ok')
  ok(r'ok'),
  @JsonValue(r'unavailable')
  unavailable(r'unavailable');

  const HealthDatabaseEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
