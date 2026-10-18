import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/l10n/l10n.dart';

class WelcomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SolaSpace.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              SolaText(l10n.appName, style: SolaTextStyle.display),
              const SizedBox(height: SolaSpace.space4),
              SolaText(l10n.welcomeTagline, color: SolaColors.inkMuted),
              const Spacer(flex: 2),
              SolaButton(
                key: const Key('welcome_log_in'),
                label: l10n.logIn,
                variant: SolaButtonVariant.primary,
                expand: true,
                onPressed: () => context.push(AppRoutes.login),
              ),
              const SizedBox(height: SolaSpace.space3),
              SolaButton(
                key: const Key('welcome_create_account'),
                label: l10n.createAccount,
                expand: true,
                onPressed: () => context.push(AppRoutes.signup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
