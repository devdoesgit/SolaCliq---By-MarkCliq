import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/quotes/data/quote_repository.dart';

/// What [QuoteSentPage] shows, passed by the request page.
class QuoteSentArgs {
  const new({required this.estimate, required this.city, required this.phone});

  final QuoteEstimate estimate;
  final String city;

  /// The number companies will call, 10 digits.
  final String phone;
}

/// The quote request is out: the indicative estimate and what happens next.
class QuoteSentPage extends StatelessWidget {
  const new({required this.args, super.key});

  final QuoteSentArgs args;

  /// "4" for 4.0, "3.3" otherwise.
  static String _kw(num kw) =>
      kw == kw.roundToDouble() ? '${kw.round()}' : kw.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final e = args.estimate;
    final kw = l10n.estimateKw(_kw(e.kwMin), _kw(e.kwMax));
    final price = l10n.estimateLakh(
      formatLakh(e.priceMin),
      formatLakh(e.priceMax),
    );
    return SolaScreen(
      navBar: const SolaNavBar(
        trailing: BackTo(fallback: AppRoutes.home, close: true),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: SolaSpace.space10),
          SolaSuccessHeader(
            title: l10n.requestSentTitle,
            body: l10n.quoteSentBody2(args.city),
          ),
          const SizedBox(height: SolaSpace.space22),
          MergeSemantics(
            child: SolaCard(
              padding: const EdgeInsets.symmetric(
                horizontal: SolaSpace.space18,
                vertical: SolaSpace.space16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: SolaSpace.space12,
                children: [
                  SolaText(
                    l10n.indicativeEstimate,
                    style: SolaTextStyle.eyebrow,
                    color: SolaColors.muted,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: SolaText(kw, style: SolaTextStyle.estimate),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: SolaSpace.space4,
                        ),
                        child: SolaText(price, style: SolaTextStyle.bodyStrong),
                      ),
                    ],
                  ),
                  SolaText(
                    l10n.estimateNote2,
                    style: SolaTextStyle.meta,
                    color: SolaColors.muted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: SolaSpace.space14),
          SolaStepsCard(
            steps: [
              SolaStep(l10n.quoteStep1Title, l10n.quoteStep1Sub2),
              SolaStep(l10n.quoteStep2Title2, l10n.quoteStep2Sub2),
              SolaStep(l10n.quoteStep3Title, l10n.quoteStep3Sub2),
            ],
          ),
        ],
      ),
      bottom: SolaBottomBar(
        children: [
          SolaButton(
            key: const Key('quote_sent_home'),
            label: l10n.backToHome,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
