import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Shown for the moment it takes to read the stored login at start-up.
class SplashPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SolaText(context.l10n.appName, style: SolaTextStyle.h1),
      ),
    );
  }
}
