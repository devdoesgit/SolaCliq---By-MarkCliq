import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Development only: lets forms be sent with nothing typed, to walk the
/// screens against the mock. On submit, every empty field takes an
/// illustrative sample value and every unanswered choice a default, so the
/// mock still gets a valid request. Never on in production.
///
/// On by default in the development flavor; switch it in the workspace
/// sheet under Development, or start with
/// `--dart-define=QUICK_FORMS=false`.
class QuickForms {
  new({required bool available})
    : enabled = ValueNotifier(available && _default),
      _available = available;

  static const _default = bool.fromEnvironment(
    'QUICK_FORMS',
    defaultValue: true,
  );

  final bool _available;

  /// Whether forms fill their blanks on submit.
  final ValueNotifier<bool> enabled;

  /// Whether the switch exists at all (development flavor only).
  bool get available => _available;

  /// Upload id used for documents that were never picked.
  static const sampleUploadId = '01928f6e-0000-7000-8000-00000000d0c1';

  void dispose() => enabled.dispose();
}

extension QuickFormsContext on BuildContext {
  /// Whether quick forms are on here. Off when no [QuickForms] is provided.
  bool get quickForms {
    try {
      return read<QuickForms>().enabled.value;
    } on ProviderNotFoundException {
      return false;
    }
  }

  /// With quick forms on, puts [sample] into [controller] if it is empty.
  void fillBlank(TextEditingController controller, String sample) {
    if (quickForms && controller.text.trim().isEmpty) {
      controller.text = sample;
    }
  }
}
