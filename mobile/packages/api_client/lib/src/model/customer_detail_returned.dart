//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/task_note.dart';
import 'package:api_client/src/model/kyc_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_detail_returned.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerDetailReturned {
  /// Returns a new [CustomerDetailReturned] instance.
  CustomerDetailReturned({
    required this.kind,

    required this.title,

    required this.note,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final KycKind kind;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'note', required: true, includeIfNull: false)
  final TaskNote note;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerDetailReturned &&
            runtimeType == other.runtimeType &&
            equals([kind, title, note], [other.kind, other.title, other.note]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([kind, title, note]);

  factory CustomerDetailReturned.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailReturnedFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDetailReturnedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
