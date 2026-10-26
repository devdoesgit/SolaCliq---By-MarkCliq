import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled font so tests and goldens lay out real text instead
/// of the test font's blocks.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader('packages/sola_ui/$family');
    for (final file in files) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Inter', ['Inter-Variable.ttf']);
  await testMain();
}
