import 'package:material_ui/material_ui.dart';

/// The Android resource-id / iOS accessibility identifier for a widget with
/// a `ValueKey<String>`, so tests and tools such as mobile-mcp can find it.
String? semanticsIdentifier(Key? key) =>
    key is ValueKey<String> ? key.value : null;
