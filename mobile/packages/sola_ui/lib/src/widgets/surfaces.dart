import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';
import 'package:sola_ui/src/widgets/rows.dart';

/// The tinted background gradients: cream by default, one per role on the
/// company homes so people know where they are at a glance.
enum SolaBackground {
  /// Cream: sign in, personal, forms.
  cream(SolaColors.cream, SolaColors.creamDeep),

  /// Stone: the agent's screens.
  stone(SolaColors.bgStoneTop, SolaColors.bgStoneBottom),

  /// Sand: the worker's screens.
  sand(SolaColors.bgSandTop, SolaColors.bgSandBottom),

  /// Sky: the customer's screens.
  sky(SolaColors.bgSkyTop, SolaColors.bgSkyBottom);

  new(this.top, this.bottom);

  /// Colour at the top.
  final Color top;

  /// Colour at the bottom.
  final Color bottom;

  /// The gradient, top to bottom.
  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [top, bottom],
  );
}

/// A screen of the iOS v2 layout: the tinted background, content 20px in
/// from the sides that scrolls under a pinned [bottom] (buttons or the tab
/// bar), and the safe areas handled.
class SolaScreen extends StatelessWidget {
  /// Creates the screen.
  const new({
    required this.body,
    this.background = SolaBackground.cream,
    this.navBar,
    this.bottom,
    this.bottomOverlaps = false,
    this.padding = const EdgeInsets.symmetric(horizontal: SolaSpace.space20),
    super.key,
  });

  /// The content, scrolled when taller than the screen.
  final Widget body;

  /// The background tint.
  final SolaBackground background;

  /// Pinned at the top, usually a `SolaNavBar`.
  final Widget? navBar;

  /// Pinned at the bottom: a `SolaBottomBar` or a `SolaTabBar`.
  final Widget? bottom;

  /// The bottom floats over the content (the tab bar), instead of pushing
  /// it up (buttons).
  final bool bottomOverlaps;

  /// Padding around [body].
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final navBar = this.navBar;
    final bottom = this.bottom;
    return Scaffold(
      backgroundColor: background.top,
      extendBody: bottomOverlaps,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: background.gradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (navBar != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SolaSpace.space20,
                  ),
                  child: navBar,
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: padding.copyWith(
                    bottom: padding.bottom + (bottomOverlaps ? 120 : 24),
                  ),
                  child: body,
                ),
              ),
              if (!bottomOverlaps) ?bottom,
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomOverlaps ? bottom : null,
    );
  }
}

/// The pinned bottom of a form: main button and links, 20px in, 34px up.
class SolaBottomBar extends StatelessWidget {
  /// Creates the bar.
  const new({required this.children, super.key});

  /// Buttons and lines, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: SolaSpace.space20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SolaSpace.space20,
          SolaSpace.space12,
          SolaSpace.space20,
          SolaSpace.space14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: SolaSpace.space12,
          children: children,
        ),
      ),
    );
  }
}

/// A white card: 22px corners and the soft card shadow.
class SolaCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: SolaSpace.space18,
      vertical: SolaSpace.space14,
    ),
    this.color = SolaColors.surface,
    this.radius = SolaRadius.radius22,
    this.shadow = SolaShadows.card,
    super.key,
  });

  /// The content.
  final Widget child;

  /// Inner padding.
  final EdgeInsets padding;

  /// Fill.
  final Color color;

  /// Corner radius.
  final double radius;

  /// Shadow layers.
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

/// An iOS grouped list: rows in one white card, with a hairline between
/// each pair.
class SolaGroup extends StatelessWidget {
  /// Creates the group.
  const new({required this.children, super.key});

  /// The rows.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SolaCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SolaSpace.space16,
        vertical: SolaSpace.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in children.indexed) ...[
            if (i > 0) const Divider(height: SolaSize.hairline),
            row,
          ],
        ],
      ),
    );
  }
}

/// A small uppercase label above a group or row of chips.
class SolaSectionLabel extends StatelessWidget {
  /// Creates the label.
  const new(
    this.text, {
    this.trailing,
    this.color = SolaColors.muted,
    super.key,
  });

  /// The words.
  final String text;

  /// At the right, usually an "Edit" link.
  final Widget? trailing;

  /// Text colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SolaSpace.space4),
      child: Row(
        children: [
          Expanded(
            child: SolaText(text, style: SolaTextStyle.eyebrow, color: color),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// "Up next" with a "See all" action.
class SolaSectionHeader extends StatelessWidget {
  /// Creates the header.
  const new(this.title, {this.action, super.key});

  /// The heading.
  final String title;

  /// At the right, usually a muted "See all" link.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SolaSpace.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: SolaText(title, style: SolaTextStyle.section)),
          ?action,
        ],
      ),
    );
  }
}

/// A sun dot then an uppercase line: "SOLACLIQ · BY MARKCLIQ".
class SolaEyebrow extends StatelessWidget {
  /// Creates the eyebrow.
  const new(this.text, {this.color = SolaColors.ink, super.key});

  /// The words.
  final String text;

  /// Text colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: SolaSpace.space8,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: SolaColors.sun,
            shape: BoxShape.circle,
          ),
        ),
        SolaText(text, style: SolaTextStyle.eyebrow, color: color),
      ],
    );
  }
}

/// A title and the line under it, at the top of a form or sheet.
class SolaTitleBlock extends StatelessWidget {
  /// Creates the block.
  const new({
    required this.title,
    this.subtitle,
    this.style = SolaTextStyle.title,
    this.center = false,
    super.key,
  });

  /// The title.
  final String title;

  /// The line under it.
  final String? subtitle;

  /// Title style.
  final SolaTextStyle style;

  /// Centres both lines.
  final bool center;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      spacing: style == SolaTextStyle.largeTitle
          ? SolaSpace.space8
          : SolaSpace.space6,
      children: [
        SolaText(title, style: style, textAlign: align),
        if (subtitle != null)
          SolaText(subtitle, color: SolaColors.muted, textAlign: align),
      ],
    );
  }
}

/// A dark card over a photo that fades to brown at the left: an eyebrow, a
/// title, and an action at the bottom ("Get a quote").
class SolaPhotoCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.photo,
    required this.eyebrow,
    required this.title,
    required this.action,
    this.height = 196,
    super.key,
  });

  /// The photo, kept to the right.
  final SolaPhotos photo;

  /// "Free solar quote".
  final String eyebrow;

  /// "Thinking of going solar?".
  final String title;

  /// Usually a compact cream `SolaButton`.
  final Widget action;

  /// Card height.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SolaColors.brown,
        borderRadius: BorderRadius.circular(SolaRadius.radius24),
        boxShadow: SolaShadows.lift,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Image(
              image: photo.provider,
              fit: BoxFit.cover,
              alignment: const Alignment(0.4, 0),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1, -0.18),
                end: const Alignment(1, 0.18),
                stops: const [0, 0.45, 1],
                colors: [
                  SolaColors.brown.withValues(alpha: 0.92),
                  SolaColors.brown.withValues(alpha: 0.7),
                  SolaColors.brown.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SolaSpace.space18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SolaText(
                  eyebrow,
                  style: SolaTextStyle.eyebrow,
                  color: SolaColors.onBrownMuted,
                ),
                const SizedBox(height: SolaSpace.space8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: SolaText(
                    title,
                    style: SolaTextStyle.cardTitle,
                    color: SolaColors.cream,
                  ),
                ),
                const Spacer(),
                action,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
