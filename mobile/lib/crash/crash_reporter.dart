import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/*
  Where the app's errors are reported from the field
  ----------------------------------------------------------------------
  - takes an error's type, never the error: messages can quote what was
    typed or sent (a FormatException carries the text it failed on), and
    customers' details mustn't reach Google (docs/data-policy.md)
*/
abstract interface class CrashReporter {
  /// Gets ready, without holding up the first frame.
  void start();

  /// Sends one error. [source] is one of the app's own fixed words.
  void record({
    required String type,
    required StackTrace? stack,
    required String source,
    required bool fatal,
  });
}

/// Reports nothing: tests and flow tests.
class NoCrashReporter implements CrashReporter {
  const new();

  @override
  void start() {}

  @override
  void record({
    required String type,
    required StackTrace? stack,
    required String source,
    required bool fatal,
  }) {}
}

/*
  Firebase Crashlytics
  ----------------------------------------------------------------------
  - collects in release builds only: the manifest has it off, and this
    turns it on, so development never sends
  - no user id, custom keys, logs or Analytics
  - its own failures only print: thrown, they would come back to the
    error handler and be reported again
*/
class FirebaseCrashReporter implements CrashReporter {
  late final Future<bool> _ready = _init();

  Future<bool> _init() async {
    try {
      await Firebase.initializeApp();
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        kReleaseMode,
      );
      return kReleaseMode;
    } on Object catch (e) {
      debugPrint('Crash reporting unavailable: ${e.runtimeType}');
      return false;
    }
  }

  @override
  void start() => _ready.ignore();

  @override
  void record({
    required String type,
    required StackTrace? stack,
    required String source,
    required bool fatal,
  }) => _send(type, stack, source, fatal: fatal).ignore();

  Future<void> _send(
    String type,
    StackTrace? stack,
    String source, {
    required bool fatal,
  }) async {
    try {
      if (!await _ready) return;
      await FirebaseCrashlytics.instance.recordError(
        type,
        stack,
        reason: source,
        printDetails: false,
        fatal: fatal,
      );
    } on Object catch (e) {
      debugPrint('Crash report not sent: ${e.runtimeType}');
    }
  }
}
