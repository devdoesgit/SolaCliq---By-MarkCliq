import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';

/// The round back (or close) button of the navigation bar: goes back, or to
/// [fallback] when there is nothing to go back to (a deep link, a fresh
/// start).
class BackTo extends StatelessWidget {
  const new({required this.fallback, this.close = false, super.key});

  /// Where to go when nothing is behind this screen.
  final String fallback;

  /// A cross instead of a chevron: the end of a flow.
  final bool close;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SolaCircleButton(
      key: const Key('nav_back'),
      icon: close ? SolaIcons.close : SolaIcons.back,
      semanticsLabel: close ? l10n.close : l10n.back,
      onPressed: () => context.canPop() ? context.pop() : context.go(fallback),
    );
  }
}
