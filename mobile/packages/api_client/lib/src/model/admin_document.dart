//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/admin_document_file.dart';
import 'package:api_client/src/model/document_status.dart';
import 'package:api_client/src/model/kyc_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_document.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDocument {
  /// Returns a new [AdminDocument] instance.
  AdminDocument({
    required this.kind,

    required this.title,

    required this.status,

    required this.files,

    this.note,

    required this.updatedAt,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final KycKind kind;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final DocumentStatus status;

  /// The current set, 1 to 5, in the order added.
  @JsonKey(name: r'files', required: true, includeIfNull: false)
  final List<AdminDocumentFile> files;

  /// Why it was sent back.
  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  /// ISO 8601, UTC.
  @JsonKey(name: r'updated_at', required: true, includeIfNull: false)
  final DateTime updatedAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminDocument &&
            runtimeType == other.runtimeType &&
            equals(
              [kind, title, status, files, note, updatedAt],
              [
                other.kind,
                other.title,
                other.status,
                other.files,
                other.note,
                other.updatedAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([kind, title, status, files, note, updatedAt]);

  factory AdminDocument.fromJson(Map<String, dynamic> json) =>
      _$AdminDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDocumentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
