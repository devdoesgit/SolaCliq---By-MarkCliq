import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/crash/crash_reporter.dart';

class AppBlocObserver extends BlocObserver {
  const new([this._crashes = const NoCrashReporter()]);

  final CrashReporter _crashes;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    // States hold customers' details and positions: never in a release log.
    if (kDebugMode) log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    reportError(error, stackTrace, where: bloc.runtimeType.toString());
    _crashes.record(
      type: error.runtimeType.toString(),
      stack: stackTrace,
      source: 'bloc',
      fatal: false,
    );
    super.onError(bloc, error, stackTrace);
  }
}

/*
  Every error reaches the device log (logcat), in every build, and the
  crash reporter
  ----------------------------------------------------------------------
  - Flutter's own (layout, build, a provider misuse): the usual report.
    Fatal, as the screen is broken; the ones Flutter marks silent only
    go to the log
  - anything thrown in a future nobody awaited, or in a plugin: those
    never reach Flutter's handler and were silently lost before. Not
    fatal: the app carries on
  - `dart:developer`'s `log` alone only shows in DevTools, so it's kept
    for that but no longer the only place
*/
@visibleForTesting
void installErrorHandlers(CrashReporter crashes) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    log(details.exceptionAsString(), stackTrace: details.stack);
    if (details.silent) return;
    crashes.record(
      type: details.exception.runtimeType.toString(),
      stack: details.stack,
      source: 'flutter',
      fatal: true,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reportError(error, stack);
    crashes.record(
      type: error.runtimeType.toString(),
      stack: stack,
      source: 'async',
      fatal: false,
    );
    return true;
  };
  Bloc.observer = AppBlocObserver(crashes);
}

Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  CrashReporter crashes = const NoCrashReporter(),
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorHandlers(crashes);
  crashes.start();
  registerSolaFontLicenses();

  // Add cross-flavor configuration here

  runApp(await builder());
}

/// Writes an error to the device log, and to DevTools.
void reportError(Object error, StackTrace? stack, {String? where}) {
  final at = where == null ? '' : ' in $where';
  debugPrint('SolaCliq error$at: $error\n$stack');
  log('error$at: $error', error: error, stackTrace: stack);
}
