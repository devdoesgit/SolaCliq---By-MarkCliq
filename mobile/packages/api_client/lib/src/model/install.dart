//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/install_next_visit.dart';
import 'package:api_client/src/model/install_payment.dart';
import 'package:api_client/src/model/install_stage.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'install.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Install {
  /// Returns a new [Install] instance.
  Install({
    required this.systemKw,

    required this.place,

    required this.stageIndex,

    required this.stageCount,

    required this.total,

    required this.subsidy,

    this.handedOverOn,

    this.upiUri,

    this.nextVisit,

    required this.stages,

    required this.payments,
  });

  @JsonKey(name: r'system_kw', required: true, includeIfNull: false)
  final num systemKw;

  @JsonKey(name: r'place', required: true, includeIfNull: false)
  final String place;

  @JsonKey(name: r'stage_index', required: true, includeIfNull: false)
  final int stageIndex;

  @JsonKey(name: r'stage_count', required: true, includeIfNull: false)
  final int stageCount;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  /// PM Surya Ghar, paid by the government to the customer.
  @JsonKey(name: r'subsidy', required: true, includeIfNull: false)
  final int subsidy;

  @JsonKey(name: r'handed_over_on', required: false, includeIfNull: false)
  final String? handedOverOn;

  /// Pays the payment that is due, through any UPI app.
  @JsonKey(name: r'upi_uri', required: false, includeIfNull: false)
  final String? upiUri;

  @JsonKey(name: r'next_visit', required: false, includeIfNull: false)
  final InstallNextVisit? nextVisit;

  @JsonKey(name: r'stages', required: true, includeIfNull: false)
  final List<InstallStage> stages;

  @JsonKey(name: r'payments', required: true, includeIfNull: false)
  final List<InstallPayment> payments;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Install &&
            runtimeType == other.runtimeType &&
            equals(
              [
                systemKw,
                place,
                stageIndex,
                stageCount,
                total,
                subsidy,
                handedOverOn,
                upiUri,
                nextVisit,
                stages,
                payments,
              ],
              [
                other.systemKw,
                other.place,
                other.stageIndex,
                other.stageCount,
                other.total,
                other.subsidy,
                other.handedOverOn,
                other.upiUri,
                other.nextVisit,
                other.stages,
                other.payments,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        systemKw,
        place,
        stageIndex,
        stageCount,
        total,
        subsidy,
        handedOverOn,
        upiUri,
        nextVisit,
        stages,
        payments,
      ]);

  factory Install.fromJson(Map<String, dynamic> json) =>
      _$InstallFromJson(json);

  Map<String, dynamic> toJson() => _$InstallToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
