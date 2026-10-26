import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Three slides on what SolaCliq does, with sample pictures, before log in.
/// Swipe or "Next"; "Skip" and the last slide's "Log in" go to log in.
class IntroPage extends StatefulWidget {
  const new({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  static const _count = 3;
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _logIn() => context.go(AppRoutes.login);

  void _next() => _pages.nextPage(
    duration: SolaMotion.durationMedium,
    curve: SolaMotion.easeStandard,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final last = _index == _count - 1;
    final slides = [
      (l10n.intro1Title, l10n.intro1Body, const _StagesPicture()),
      (l10n.intro2Title, l10n.intro2Body, const _PhotosPicture()),
      (l10n.intro3Title, l10n.intro3Body, const _ExpensePicture()),
    ];
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: SolaBackground.cream.gradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SolaSpace.space20,
                ),
                child: SolaNavBar(
                  trailing: SolaTextLink(
                    l10n.skip,
                    key: const Key('intro_skip'),
                    color: SolaColors.muted,
                    style: SolaTextStyle.bodyLg,
                    onPressed: _logIn,
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    for (final (title, body, picture) in slides)
                      _Slide(title: title, body: body, picture: picture),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SolaSpace.space20,
                  SolaSpace.space16,
                  SolaSpace.space20,
                  SolaSpace.space34,
                ),
                child: Semantics(
                  label: l10n.slideOf('${_index + 1}', '$_count'),
                  child: ExcludeSemantics(child: _Dots(index: _index)),
                ),
              ),
              SolaBottomBar(
                children: [
                  SolaButton(
                    key: const Key('intro_next'),
                    label: last ? l10n.logIn : l10n.next,
                    onPressed: last ? _logIn : _next,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const new({required this.title, required this.body, required this.picture});

  final String title;
  final String body;
  final Widget picture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SolaSpace.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The picture gives way on short screens; the words never do.
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: Semantics(
                image: true,
                label: context.l10n.introSampleLabel,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(SolaRadius.radius32),
                      gradient: const LinearGradient(
                        begin: Alignment(-0.35, -1),
                        end: Alignment(0.35, 1),
                        colors: [SolaColors.butterLight, SolaColors.butter],
                      ),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(width: 300, child: picture),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: SolaSpace.space26),
          SolaText(title, style: SolaTextStyle.intro),
          const SizedBox(height: SolaSpace.space10),
          SolaText(body, style: SolaTextStyle.bodyLg, color: SolaColors.muted),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const new({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: SolaSpace.space6,
      children: [
        for (var i = 0; i < _IntroPageState._count; i++)
          AnimatedContainer(
            duration: SolaMotion.durationFast,
            curve: SolaMotion.easeStandard,
            width: i == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? SolaColors.ink : SolaColors.dashed,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// Slide 1: a customer's stage bar and a done task.
class _StagesPicture extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space12,
      children: [
        SolaProgressCard(
          label: l10n.introSampleCustomer,
          trailing: l10n.welcomeStage,
          trailingTone: SolaTone.live,
          segments: [
            for (var i = 0; i < 7; i++)
              SolaSegment(1, i < 4 ? SolaColors.sun : SolaColors.track),
          ],
          stageLabels: [
            l10n.stageSurvey,
            l10n.stageInstall,
            l10n.stageHandover,
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: SolaSpace.space20),
          child: SolaCard(
            padding: const EdgeInsets.symmetric(
              horizontal: SolaSpace.space16,
              vertical: SolaSpace.space4,
            ),
            child: SolaListRow(
              title: l10n.introPanelsFitted,
              subtitle: l10n.introPanelsWhen,
              leading: const SolaThumb(photo: SolaPhotos.thumbInstall),
              trailing: SolaPill(
                l10n.done,
                tone: SolaTone.success,
                icon: SolaIcons.check,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Slide 2: a grid of proof photos.
class _PhotosPicture extends StatelessWidget {
  const new();

  static const List<SolaPhotos> _photos = [
    SolaPhotos.thumbInstall,
    SolaPhotos.thumbInverter,
    SolaPhotos.thumbMeter,
    SolaPhotos.thumbSurvey,
    SolaPhotos.quoteHome,
  ];

  @override
  Widget build(BuildContext context) {
    Widget tile(Widget child, {Color? color}) => Container(
      width: 92,
      height: 92,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SolaRadius.radius18),
        boxShadow: color == null ? SolaShadows.soft : null,
      ),
      child: child,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: SolaSpace.space12,
      children: [
        Wrap(
          spacing: SolaSpace.space10,
          runSpacing: SolaSpace.space10,
          children: [
            for (final photo in _photos)
              tile(Image(image: photo.provider, fit: BoxFit.cover)),
            tile(
              const Center(child: SolaIcon(SolaIcons.camera, size: 30)),
              color: SolaColors.sun,
            ),
          ],
        ),
        SolaPill(context.l10n.introPhotos, icon: SolaIcons.camera),
      ],
    );
  }
}

/// Slide 3: an approved expense and the admin's reply.
class _ExpensePicture extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space12,
      children: [
        SolaCard(
          padding: const EdgeInsets.symmetric(
            horizontal: SolaSpace.space18,
            vertical: SolaSpace.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SolaSpace.space12,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SolaText(
                      l10n.introExpense,
                      style: SolaTextStyle.eyebrow,
                      color: SolaColors.muted,
                    ),
                  ),
                  SolaPill(
                    l10n.statusApproved,
                    tone: SolaTone.success,
                    icon: SolaIcons.check,
                  ),
                ],
              ),
              SolaText(formatRupees(124000), style: SolaTextStyle.stat),
              SolaText(
                l10n.introExpenseNote,
                style: SolaTextStyle.small,
                color: SolaColors.muted,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 40),
          child: SolaCard(
            padding: const EdgeInsets.symmetric(
              horizontal: SolaSpace.space14,
              vertical: SolaSpace.space12,
            ),
            child: Row(
              spacing: SolaSpace.space10,
              children: [
                const SolaAvatar(
                  initials: 'HS',
                  size: 32,
                  color: SolaColors.brown,
                  foreground: SolaColors.cream,
                ),
                Expanded(child: SolaText(l10n.introReply)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
