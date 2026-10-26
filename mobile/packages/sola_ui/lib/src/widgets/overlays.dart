import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/icons/sola_icon.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';
import 'package:sola_ui/src/widgets/controls.dart';
import 'package:sola_ui/src/widgets/semantics_id.dart';
import 'package:sola_ui/src/widgets/tappable.dart';

/// Opens an iOS-style sheet: cream, 34px top corners, a handle, a title
/// with "Done". Closes on Done, the scrim, a drag down or back, with no
/// result.
Future<T?> showSolaSheet<T>({
  required BuildContext context,
  required String title,
  required String doneLabel,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: const AnimationStyle(
      curve: SolaMotion.easeStandard,
      duration: SolaMotion.durationMedium,
    ),
    builder: (context) =>
        SolaSheet(title: title, doneLabel: doneLabel, child: builder(context)),
  );
}

/// The frame of a [showSolaSheet] sheet.
class SolaSheet extends StatelessWidget {
  /// Creates the frame.
  const new({
    required this.title,
    required this.doneLabel,
    required this.child,
    super.key,
  });

  /// "Workspaces".
  final String title;

  /// The close link: "Done".
  final String doneLabel;

  /// The content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: SolaSpace.space20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SolaSpace.space20,
          SolaSpace.space10,
          SolaSpace.space20,
          SolaSpace.space20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SolaSpace.space14,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: SolaColors.handle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SolaText(title, style: SolaTextStyle.sheetTitle),
                ),
                SolaTextLink(
                  doneLabel,
                  key: const Key('sheet_done'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}

/// One item of a [SolaTabBar].
@immutable
class SolaTabItem {
  /// Creates an item. A [raised] item is the bar's main action: a sun
  /// circle lifted above the bar.
  const new({
    required this.key,
    required this.label,
    required this.icon,
    this.raised = false,
  });

  /// Identifies the item, e.g. `ValueKey('tab_home')`.
  final ValueKey<String> key;

  /// What a screen reader says.
  final String label;

  /// The icon; the bar shows no words, as in the designs.
  final SolaIcons icon;

  /// The main action, drawn as a lifted sun circle.
  final bool raised;
}

/// The floating tab bar: icons only, a sun dot under the current one, and
/// a lifted sun button for the main action.
class SolaTabBar extends StatelessWidget {
  /// Creates the bar.
  const new({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// The items, left to right.
  final List<SolaTabItem> items;

  /// Index of the destination on screen.
  final int selectedIndex;

  /// Called with the index tapped.
  final ValueChanged<int> onSelected;

  // How far the raised action rises above the bar.
  static const double _lift = 26 - (SolaSize.tabBar - SolaSize.tabAction) / 2;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: SolaSpace.space26),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SolaSpace.space20),
        child: SizedBox(
          height: SolaSize.tabBar + _lift,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const inset = SolaSpace.space10;
              final fixed =
                  items.where((i) => i.raised).length * SolaSize.tabAction;
              final flexCount = items.where((i) => !i.raised).length;
              final slot =
                  (constraints.maxWidth - 2 * inset - fixed) / flexCount;
              var x = inset;
              final raisedLefts = <int, double>{};
              for (final (i, item) in items.indexed) {
                if (item.raised) raisedLefts[i] = x;
                x += item.raised ? SolaSize.tabAction : slot;
              }
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: SolaSize.tabBar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: inset),
                      decoration: BoxDecoration(
                        color: const Color(0xF0FFFFFF),
                        borderRadius: BorderRadius.circular(
                          SolaSize.tabBar / 2,
                        ),
                        boxShadow: SolaShadows.nav,
                      ),
                      child: Row(
                        children: [
                          for (final (i, item) in items.indexed)
                            if (item.raised)
                              const SizedBox(width: SolaSize.tabAction)
                            else
                              Expanded(
                                child: _Tab(
                                  item: item,
                                  selected: i == selectedIndex,
                                  onTap: () => onSelected(i),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  for (final MapEntry(key: i, value: left)
                      in raisedLefts.entries)
                    Positioned(
                      top: 0,
                      left: left,
                      child: _Raised(
                        item: items[i],
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const new({required this.item, required this.selected, required this.onTap});

  final SolaTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SolaTappable(
      key: item.key,
      identifier: semanticsIdentifier(item.key),
      semanticsLabel: item.label,
      selected: selected,
      onTap: onTap,
      builder: (context, state) => SizedBox(
        height: SolaSize.tabBar,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: [
            const SizedBox(height: 6),
            AnimatedOpacity(
              duration: SolaMotion.durationInstant,
              opacity: state.pressed ? 0.5 : 1,
              child: SolaIcon(
                item.icon,
                color: selected ? SolaColors.ink : SolaColors.faint,
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: selected ? SolaColors.sunDeep : null,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Raised extends StatelessWidget {
  const new({required this.item, required this.onTap});

  final SolaTabItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SolaTappable(
      key: item.key,
      identifier: semanticsIdentifier(item.key),
      semanticsLabel: item.label,
      onTap: onTap,
      builder: (context, state) => AnimatedScale(
        duration: SolaMotion.durationInstant,
        scale: state.pressed ? 0.94 : 1,
        child: Container(
          width: SolaSize.tabAction,
          height: SolaSize.tabAction,
          decoration: BoxDecoration(
            color: SolaColors.sun,
            shape: BoxShape.circle,
            boxShadow: SolaShadows.sunLift,
            border: state.focused
                ? Border.all(color: SolaColors.focus, width: 2)
                : null,
          ),
          child: Center(child: SolaIcon(item.icon, size: 24, strokeWidth: 2)),
        ),
      ),
    );
  }
}

/// Six white boxes for a verification code; the next one to fill is
/// outlined. Typing goes to a hidden field so paste and autofill work.
class SolaCodeInput extends StatefulWidget {
  /// Creates the input.
  const new({
    required ValueKey<String> super.key,
    required this.controller,
    required this.label,
    this.length = 6,
    this.onCompleted,
    this.error = false,
  });

  /// Holds the code.
  final TextEditingController controller;

  /// What a screen reader says.
  final String label;

  /// Number of digits.
  final int length;

  /// Called once every digit is typed.
  final ValueChanged<String>? onCompleted;

  /// Outlines the boxes in red.
  final bool error;

  @override
  State<SolaCodeInput> createState() => _SolaCodeInputState();
}

class _SolaCodeInputState extends State<SolaCodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
    final text = widget.controller.text;
    if (text.length == widget.length) widget.onCompleted?.call(text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.key! as ValueKey<String>;
    final text = widget.controller.text;
    final active = _focus.hasFocus
        ? text.length.clamp(0, widget.length - 1)
        : -1;
    return Stack(
      children: [
        Row(
          spacing: SolaSpace.space8,
          children: [
            for (var i = 0; i < widget.length; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: SolaMotion.durationFast,
                  height: 60,
                  decoration: BoxDecoration(
                    color: SolaColors.surface,
                    borderRadius: BorderRadius.circular(SolaRadius.radius16),
                    boxShadow: SolaShadows.card,
                    border: widget.error
                        ? Border.all(color: SolaColors.danger, width: 2)
                        : i == active
                        ? Border.all(color: SolaColors.ink, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: i < text.length
                          ? Text(
                              text[i],
                              style: SolaTextStyle.keypad.textStyle().copyWith(
                                fontSize: 28,
                              ),
                            )
                          : i == active
                          ? Container(
                              width: 2,
                              height: 26,
                              color: SolaColors.ink,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              key: ValueKey('${key.value}_input'),
              controller: widget.controller,
              focusNode: _focus,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              showCursor: false,
              enableInteractiveSelection: false,
              decoration: InputDecoration.collapsed(hintText: widget.label),
              style: const TextStyle(height: 3.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// A number pad for typing an amount: 1-9, a point, 0 and delete.
class SolaKeypad extends StatelessWidget {
  /// Creates the pad.
  const new({
    required this.onKey,
    required this.onDelete,
    required this.deleteLabel,
    super.key,
  });

  /// Called with "0"-"9" or ".".
  final ValueChanged<String> onKey;

  /// Deletes the last character.
  final VoidCallback onDelete;

  /// What a screen reader says for delete.
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', ''];
    return GridView(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        // A full tap target per key, whatever the phone's width.
        mainAxisExtent: SolaSize.tapMin,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final k in keys)
          SolaTappable(
            key: ValueKey('keypad_${k.isEmpty ? 'delete' : k}'),
            identifier:
                'keypad_${k.isEmpty
                    ? 'delete'
                    : k == '.'
                    ? 'point'
                    : k}',
            semanticsLabel: k.isEmpty ? deleteLabel : k,
            onTap: () => k.isEmpty ? onDelete() : onKey(k),
            builder: (context, state) => Container(
              decoration: BoxDecoration(
                color: state.pressed ? SolaColors.tan : null,
                borderRadius: BorderRadius.circular(SolaRadius.radius12),
              ),
              child: Center(
                child: k.isEmpty
                    ? const SolaIcon(SolaIcons.backspace, size: 24)
                    : SolaText(k, style: SolaTextStyle.keypad),
              ),
            ),
          ),
      ],
    );
  }
}
