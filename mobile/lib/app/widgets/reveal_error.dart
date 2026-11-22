import 'package:material_ui/material_ui.dart';

/*
  After a form refuses to send, brings its first problem into view
  ----------------------------------------------------------------------
  - [fields] in the order they appear, each with whether it has an error
    and the key its widget already has; the first with an error is
    scrolled to, so an error off screen or behind the bottom button
    isn't missed (QA-09)
  - found by that key below [form], so there's no second key to attach
    (and forget). A key that's on no widget fails in debug
  - after the frame, so the error text is laid out before scrolling
*/
void revealFirstError(BuildContext form, Iterable<(bool, Key)> fields) {
  for (final (hasError, key) in fields) {
    if (!hasError) continue;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!form.mounted) return;
      final target = _withKey(form, key);
      assert(target != null, 'revealFirstError: no widget has $key');
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.3,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
    return;
  }
}

BuildContext? _withKey(BuildContext form, Key key) {
  BuildContext? found;
  void visit(Element element) {
    if (found != null) return;
    if (element.widget.key == key) {
      found = element;
    } else {
      element.visitChildElements(visit);
    }
  }

  form.visitChildElements(visit);
  return found;
}
