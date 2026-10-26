import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';

/// The request's error as an announced notice, or nothing.
class FailureNotice extends StatelessWidget {
  const new({required this.state, this.action, super.key});

  final SubmitState state;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final failure = state.failure;
    if (state.status != SubmitStatus.failure || failure == null) {
      return const SizedBox.shrink();
    }
    return SolaNotice(
      key: const Key('failure_notice'),
      title: failure.message(context.l10n),
      announce: true,
      action: action,
    );
  }
}
