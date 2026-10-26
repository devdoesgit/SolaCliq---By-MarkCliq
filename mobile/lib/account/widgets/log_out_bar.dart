import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/l10n/l10n.dart';

/// The white "Log out" button. Disabled after the first tap; the router
/// leaves once the person is signed out.
class LogOutButton extends StatefulWidget {
  const new({this.variant = SolaButtonVariant.white, super.key});

  /// White on the sheets; red text on the worker's profile.
  final SolaButtonVariant variant;

  @override
  State<LogOutButton> createState() => _LogOutButtonState();
}

class _LogOutButtonState extends State<LogOutButton> {
  bool _busy = false;

  Future<void> _logOut() async {
    setState(() => _busy = true);
    await context.read<AuthRepository>().logOut();
  }

  @override
  Widget build(BuildContext context) {
    return SolaButton(
      key: const Key('log_out'),
      label: context.l10n.logOut,
      variant: widget.variant,
      icon: SolaIcons.logOut,
      onPressed: _busy ? null : () => unawaited(_logOut()),
    );
  }
}

/// [LogOutButton] pinned to the bottom of a screen.
class LogOutBar extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const SolaBottomBar(children: [LogOutButton()]);
  }
}
