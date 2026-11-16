import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/data/auth_failure.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';

/// The request's error as an announced notice, or nothing.
class FailureNotice extends StatelessWidget {
  const new({required this.state, this.action, this.messageFor, super.key});

  final SubmitState state;
  final Widget? action;

  /// A screen's own wording for some failures (null: the usual text).
  final String? Function(AuthFailureCode failure)? messageFor;

  @override
  Widget build(BuildContext context) {
    final failure = state.failure;
    if (state.status != SubmitStatus.failure || failure == null) {
      return const SizedBox.shrink();
    }
    return SolaNotice(
      key: const Key('failure_notice'),
      title: messageFor?.call(failure) ?? failure.message(context.l10n),
      announce: true,
      action: action,
    );
  }
}
