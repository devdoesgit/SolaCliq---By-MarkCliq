import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';

/// The line icons of the iOS v2 designs, on a 24px grid, drawn from their
/// SVG paths so they match exactly.
enum SolaIcons {
  /// Back chevron.
  back('<path d="M15 5l-7 7 7 7"/>'),

  /// Close cross.
  close('<path d="M6 6l12 12M18 6L6 18"/>'),

  /// Forward chevron (rows that open something).
  chevronRight('<path d="M9 6l6 6-6 6"/>', 2),

  /// Downward chevron (the workspace line).
  chevronDown('<path d="M6 9l6 6 6-6"/>', 2.2),

  /// Tick.
  check('<path d="M5 12.5l4.5 4.5L19 7.5"/>', 2.2),

  /// Camera.
  camera(
    '<path d="M4 8h3l2-3h6l2 3h3v11H4z"/><circle cx="12" cy="13" r="3.5"/>',
    2,
  ),

  /// In review: an hourglass.
  hourglass(
    '<path d="M7 3h10M7 21h10M8 3c0 5 8 5 8 9s-8 4-8 9M16 3c0 5-8 5-8 9"/>',
    2.2,
  ),

  /// Live power: a bolt.
  bolt('<path d="M13 3L5 13.5h6L10 21l8-10.5h-6z"/>', 2.2),

  /// Expenses: a receipt.
  receipt('<path d="M6 3h12v18l-3-2-3 2-3-2-3 2z"/><path d="M9 8h6M9 12h6"/>'),

  /// Needs a fix: an alarm clock.
  alarm(
    '<circle cx="12" cy="13" r="7"/><path d="M12 9.5V13l2.5 1.5M4 5l3-2.5M20 '
    '5l-3-2.5"/>',
    2.2,
  ),

  /// Notifications.
  bell(
    '<path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 1.5H4.5z"/><path d="M10 20.5h4"/>',
  ),

  /// Home tab.
  home('<path d="M4 10.5l8-6.5 8 6.5V20H4z"/><path d="M10 20v-5h4v5"/>'),

  /// People.
  users(
    '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/> '
    '<path d="M16 4.5a3.5 3.5 0 0 1 0 7M18 14a6 6 0 0 1 3.5 6"/>',
  ),

  /// Add.
  plus('<path d="M12 5v14M5 12h14"/>', 2),

  /// KYC: a document.
  file('<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4M10 12h5M10 16h5"/>'),

  /// Profile.
  user(
    '<circle cx="12" cy="8" r="4"/><path d="M4.5 20.5a7.5 7.5 0 0 1 15 0"/>',
  ),

  /// Subsidy: a shield with a tick.
  shield(
    '<path d="M12 3l7 3v5c0 5-3.5 8.5-7 10-3.5-1.5-7-5-7-10V6z"/> '
    '<path d="M9 12l2 2 4-4"/>',
    1.8,
  ),

  /// Track: a route.
  route(
    '<circle cx="6" cy="18" r="2.5"/><circle cx="18" cy="6" r="2.5"/> '
    '<path d="M8.5 18H15a3 3 0 0 0 0-6H9a3 3 0 0 1 0-6h6.5"/>',
  ),

  /// Support: a speech bubble.
  chat('<path d="M4 5h16v11H9l-5 4z"/>', 2),

  /// Payments: a wallet.
  wallet('<path d="M4 7h16v12H4z"/><path d="M4 7l12-3v3M16 13h4"/>'),

  /// Energy and quotes: the sun.
  sun(
    '<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 '
    '12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"/>',
  ),

  /// Tasks: a dotted list.
  list(
    '<path d="M9 6h11M9 12h11M9 18h11"/><circle cx="4.5" cy="6" r="0.9"/> '
    '<circle cx="4.5" cy="12" r="0.9"/><circle cx="4.5" cy="18" r="0.9"/>',
  ),

  /// Secured: a padlock.
  lock(
    '<rect x="5" y="10.5" width="14" height="10" rx="2"/> '
    '<path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/>',
    2,
  ),

  /// Log out.
  logOut('<path d="M14 4h5v16h-5M10 8l-4 4 4 4M6 12h10"/>'),

  /// Learn: a book.
  book(
    '<path d="M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2z"/><path d="M4 19V5"/>',
  ),

  /// A solar company: buildings.
  building(
    '<path d="M4 21V5l8-2v18M12 21V9l8 2v10M3 21h18"/> '
    '<path d="M7 8h2M7 12h2M7 16h2M15 14h2M15 17h2"/>',
  ),

  /// Delete the last digit.
  backspace(
    '<path d="M9 5h11v14H9l-6-7z"/><path d="M12.5 9.5l5 5M17.5 9.5l-5 5"/>',
  ),

  /// A warning: a triangle with a mark.
  alert('<path d="M12 4l9 16H3z"/><path d="M12 10v4.5M12 17.4v.1"/>', 2),

  /// Flash for the camera.
  flash('<path d="M13 3L6 13h5l-1 8 7-10h-5z"/>', 2),

  /// A place on the map.
  pin(
    '<path d="M12 21s-6.5-6.2-6.5-11a6.5 6.5 0 0 1 13 0c0 4.8-6.5 11-6.5 11z"/> '
    '<circle cx="12" cy="10" r="2.4"/>',
    2,
  ),

  /// Switch camera.
  flipCamera(
    '<path d="M4 9a8 8 0 0 1 14-3l2 2M20 15a8 8 0 0 1-14 3l-2-2"/> '
    '<path d="M20 4v4h-4M4 20v-4h4"/>',
    1.8,
  ),

  /// A task's history: a clock turning back.
  history(
    '<path d="M4 12a8 8 0 1 0 2.4-5.7L4 8.5"/><path d="M4 4v4.5h4.5M12 8v4.5l3 2"/>',
    1.9,
  ),

  /// Call.
  phone(
    '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 '
    '2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/>',
    1.9,
  ),

  /// Directions.
  navigate('<path d="M4 11l16-7-7 16-2-7z"/>', 1.9),

  /// On hold: waiting on the admin's decision.
  pause('<path d="M9 5v14M15 5v14"/>', 2),

  /// Search.
  search('<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4.5 4.5"/>'),

  /// Settings.
  settings(
    '<circle cx="12" cy="12" r="3"/><path d="M12 2.8v2.4M12 18.8v2.4M2.8 '
    '12h2.4M18.8 12h2.4M5.5 5.5l1.7 1.7M16.8 16.8l1.7 1.7M5.5 18.5l1.7-1.7 '
    'M16.8 7.2l1.7-1.7"/>',
  ),

  /// An ID card.
  idCard(
    '<rect x="3.5" y="5.5" width="17" height="13" rx="2"/><circle cx="9" '
    'cy="11" r="2"/><path d="M6 15.5c.6-1.2 1.7-1.8 3-1.8s2.4.6 3 1.8M14.5 '
    '10h3.5M14.5 13h3.5"/>',
    1.9,
  ),

  /// Help.
  help(
    '<circle cx="12" cy="12" r="8.5"/><path d="M9.6 9.5a2.5 2.5 0 1 1 3.4 '
    '2.3c-.7.3-1 .9-1 1.6v.3M12 16.8v.1"/>',
    1.9,
  );

  new(this.paths, [this.strokeWidth = 1.7]);

  /// The SVG elements, stroked in the icon's colour.
  final String paths;

  /// The stroke width the designs use for this icon.
  final double strokeWidth;
}

/// A [SolaIcons] icon in [color], [size] square. Decorative unless
/// [semanticsLabel] is given.
class SolaIcon extends StatelessWidget {
  /// Creates an icon.
  const new(
    this.icon, {
    this.size = 22,
    this.color = SolaColors.ink,
    this.strokeWidth,
    this.semanticsLabel,
    super.key,
  });

  /// Which icon.
  final SolaIcons icon;

  /// Width and height.
  final double size;

  /// Stroke colour; a colour token.
  final Color color;

  /// Overrides the icon's own stroke width.
  final double? strokeWidth;

  /// What a screen reader says; null hides the icon from them.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final hex = (color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="none" stroke="#$hex" '
        'stroke-width="${strokeWidth ?? icon.strokeWidth}" '
        'stroke-linecap="round" stroke-linejoin="round">${icon.paths}</svg>';
    final picture = SvgPicture.string(svg, width: size, height: size);
    final label = semanticsLabel;
    return label == null
        ? ExcludeSemantics(child: picture)
        : Semantics(label: label, image: true, child: picture);
  }
}
