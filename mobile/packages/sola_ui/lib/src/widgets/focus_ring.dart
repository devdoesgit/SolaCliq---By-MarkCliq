import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';

/// Paints the SolaCliq focus ring (2px solid `focus`, 2px offset) around
/// [child] when [visible], without changing its layout.
///
/// Set [inset] for full-width rows, where an outside ring would be clipped:
/// the ring is then drawn just inside the edge.
class SolaFocusRing extends StatelessWidget {
  /// Creates a focus ring around [child].
  const new({
    required this.visible,
    required this.child,
    this.inset = false,
    super.key,
  });

  /// Whether the ring shows.
  final bool visible;

  /// Draw the ring inside the element's edge instead of outside it.
  final bool inset;

  /// The element.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: visible ? _RingPainter(inset: inset) : null,
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  const new({required this.inset});

  final bool inset;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 2.0;
    // Centre the stroke on a rect one offset plus half a stroke away.
    final delta = inset ? -width / 2 : width + width / 2;
    final rect = (Offset.zero & size).inflate(delta);
    canvas.drawRect(
      rect,
      Paint()
        ..color = SolaColors.focus
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.inset != inset;
}
