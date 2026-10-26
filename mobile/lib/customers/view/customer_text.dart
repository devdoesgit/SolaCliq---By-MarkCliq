import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/view/task_text.dart';

extension KycStatusText on KycStatus {
  SolaPill pill(AppLocalizations l10n) => switch (this) {
    KycStatus.inReview => SolaPill(
      l10n.statusInReview,
      icon: SolaIcons.hourglass,
    ),
    KycStatus.needsFix => SolaPill(
      l10n.fixKyc,
      tone: SolaTone.danger,
      icon: SolaIcons.alert,
    ),
    KycStatus.approved => SolaPill(
      l10n.statusApproved,
      tone: SolaTone.success,
      icon: SolaIcons.check,
    ),
  };
}

extension CommissionStatusText on CommissionStatus {
  SolaPill pill(AppLocalizations l10n) => switch (this) {
    CommissionStatus.inReview => SolaPill(
      l10n.statusInReview,
      icon: SolaIcons.hourglass,
    ),
    CommissionStatus.approved => SolaPill(
      l10n.statusApproved,
      tone: SolaTone.success,
    ),
    CommissionStatus.payable => SolaPill(
      l10n.payable,
      tone: SolaTone.warning,
      icon: SolaIcons.wallet,
    ),
    CommissionStatus.paid => SolaPill(
      l10n.statusPaid,
      tone: SolaTone.success,
      icon: SolaIcons.check,
    ),
  };
}

extension KycKindText on KycKind {
  String label(AppLocalizations l10n) => switch (this) {
    KycKind.aadhaar => l10n.docAadhaar,
    KycKind.pan => l10n.docPan,
    KycKind.electricityBill => l10n.docBill,
    KycKind.bankProof => l10n.docBankProof,
    KycKind.roofPhoto => l10n.docRoof,
  };
}

extension CustomerSummaryText on CustomerSummary {
  String get initials => initialsOf(name);

  /// "3 kW · Sector 69, Mohali".
  String place2(AppLocalizations l10n) => l10n.kwPlace('$systemKw', place);
}
