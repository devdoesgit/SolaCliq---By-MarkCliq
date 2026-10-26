import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/l10n/l10n.dart';

/// The access request went through: what MarkCliq does next.
class RequestSentPage extends StatelessWidget {
  const new({required this.company, required this.email, super.key});

  final String company;
  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SolaScreen(
      navBar: const SolaNavBar(
        trailing: BackTo(fallback: AppRoutes.welcome, close: true),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: SolaSpace.space10),
          SolaSuccessHeader(
            title: l10n.requestSentTitle,
            body: l10n.requestSentBody2(email),
          ),
          const SizedBox(height: SolaSpace.space22),
          SolaStepsCard(
            steps: [
              SolaStep(l10n.accessStep1Title, l10n.accessStep1Sub),
              SolaStep(l10n.accessStep2Title2, l10n.accessStep2Sub2),
              SolaStep(l10n.accessStep3Title2, l10n.accessStep3Sub2),
            ],
          ),
        ],
      ),
      bottom: SolaBottomBar(
        children: [
          SolaButton(
            key: const Key('request_sent_done'),
            label: l10n.done,
            onPressed: () => context.go(AppRoutes.welcome),
          ),
        ],
      ),
    );
  }
}
