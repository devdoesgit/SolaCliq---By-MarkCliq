import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';

/// What to tell the person when a picked file is refused.
extension UploadProblemText on UploadProblem {
  String message(AppLocalizations l10n) => switch (this) {
    UploadProblem.tooLarge => l10n.fileTooBig,
  };
}
