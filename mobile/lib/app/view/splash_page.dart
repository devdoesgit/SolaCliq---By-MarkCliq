import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Shown for the moment it takes to read the stored login at start-up.
///
/// It continues Android's launch screen exactly: the same cream, and the
/// same mark over the "SolaCliq" wordmark at the same size, centred, so
/// opening the app never flashes or jumps.
class SplashPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SolaColors.cream,
      body: Center(child: SolaSplashMark(semanticsLabel: context.l10n.appName)),
    );
  }
}
