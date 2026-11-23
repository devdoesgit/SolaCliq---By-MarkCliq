import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/leads/data/lead_repository.dart';

extension LeadStatusText on LeadStatus {
  String label(AppLocalizations l10n) => switch (this) {
    LeadStatus.fresh => l10n.leadStatusNew,
    LeadStatus.contacted => l10n.leadStatusContacted,
    LeadStatus.won => l10n.leadStatusWon,
    LeadStatus.lost => l10n.leadStatusLost,
  };

  SolaPill pill(AppLocalizations l10n) => SolaPill(
    label(l10n),
    tone: switch (this) {
      LeadStatus.fresh => SolaTone.warning,
      LeadStatus.contacted => SolaTone.neutral,
      LeadStatus.won => SolaTone.success,
      LeadStatus.lost => SolaTone.neutral,
    },
  );
}
