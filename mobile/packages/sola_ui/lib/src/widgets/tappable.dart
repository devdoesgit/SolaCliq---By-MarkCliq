import 'package:material_ui/material_ui.dart';

/// The interaction state a [SolaTappable] passes to its builder.
@immutable
class SolaTapState {
  /// Creates a tap state.
  const new({
    required this.enabled,
    required this.pressed,
    required this.hovered,
    required this.focused,
  });

  /// Whether the element responds to taps.
  final bool enabled;

  /// Whether a finger or pointer is down on it.
  final bool pressed;

  /// Whether a mouse is over it.
  final bool hovered;

  /// Whether the focus ring should show (keyboard or switch access).
  final bool focused;
}

/// Base for every tappable SolaCliq widget: tap, keyboard activation, focus,
/// hover, pressed state and button semantics in one place.
///
/// Feedback is immediate: the pressed state is set on pointer down, with no
/// animation.
class SolaTappable extends StatefulWidget {
  /// Creates a tappable element. [semanticsLabel] is what screen readers and
  /// mobile-mcp read.
  const new({
    required this.semanticsLabel,
    required this.onTap,
    required this.builder,
    this.isButton = true,
    this.selected,
    this.identifier,
    super.key,
  });

  /// Spoken label; replaces the semantics of everything the builder returns.
  final String semanticsLabel;

  /// Called on tap or keyboard activation. Null disables the element.
  final VoidCallback? onTap;

  /// Whether screen readers announce it as a button.
  final bool isButton;

  /// For one of a set, such as a tab: whether it is the chosen one. Null
  /// when the element isn't selectable.
  final bool? selected;

  /// Stable id exposed to the platform's accessibility tree.
  final String? identifier;

  /// Builds the element for the current state.
  final Widget Function(BuildContext context, SolaTapState state) builder;

  @override
  State<SolaTappable> createState() => _SolaTappableState();
}

class _SolaTappableState extends State<SolaTappable> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.onTap != null;

  // Set from callbacks that can fire during teardown, so guard on mounted.
  void _set(VoidCallback change) {
    if (mounted) setState(change);
  }

  @override
  void didUpdateWidget(SolaTappable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _pressed = false;
      _hovered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    return Semantics(
      container: true,
      button: widget.isButton,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticsLabel,
      identifier: widget.identifier,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowFocusHighlight: (value) => _set(() => _focused = value),
        onShowHoverHighlight: (value) => _set(() => _hovered = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: enabled ? (_) => _set(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => _set(() => _pressed = false) : null,
          onTapCancel: enabled ? () => _set(() => _pressed = false) : null,
          onTap: widget.onTap,
          child: widget.builder(
            context,
            SolaTapState(
              enabled: enabled,
              pressed: _pressed,
              hovered: _hovered,
              focused: _focused,
            ),
          ),
        ),
      ),
    );
  }
}
