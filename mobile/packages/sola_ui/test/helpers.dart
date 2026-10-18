import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';

extension PumpSola on WidgetTester {
  /// Pumps [child] in a SolaCliq-themed screen at a typical phone width.
  Future<void> pumpSola(Widget child) {
    return pumpWidget(
      MaterialApp(
        theme: SolaTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(SolaSpace.space4),
            child: child,
          ),
        ),
      ),
    );
  }
}
