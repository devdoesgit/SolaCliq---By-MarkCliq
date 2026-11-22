import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/bootstrap.dart';
import 'package:solacliq/crash/crash_reporter.dart';

class _Reports implements CrashReporter {
  final List<({String type, String source, bool fatal})> all = [];

  @override
  void start() {}

  @override
  void record({
    required String type,
    required StackTrace? stack,
    required String source,
    required bool fatal,
  }) => all.add((type: type, source: source, fatal: fatal));
}

class _Counter extends Cubit<int> {
  new() : super(0);

  void fail(Object error) => addError(error, StackTrace.current);
}

// What an error can carry, and mustn't leave the phone.
const _private = 'asha@example.com 9814022671 H.No 214';

void main() {
  late _Reports reports;

  setUp(() => reports = _Reports());

  /// Runs [act] with the app's handlers, then puts the test's back.
  void withHandlers(void Function() act) {
    final flutter = FlutterError.onError;
    final present = FlutterError.presentError;
    final platform = PlatformDispatcher.instance.onError;
    final observer = Bloc.observer;
    try {
      FlutterError.presentError = (_) {};
      installErrorHandlers(reports);
      act();
    } finally {
      FlutterError.onError = flutter;
      FlutterError.presentError = present;
      PlatformDispatcher.instance.onError = platform;
      Bloc.observer = observer;
    }
  }

  testWidgets("a screen's error is fatal, sent as its type only", (_) async {
    withHandlers(
      () => FlutterError.onError!(
        FlutterErrorDetails(exception: StateError(_private)),
      ),
    );
    expect(reports.all, [(type: 'StateError', source: 'flutter', fatal: true)]);
  });

  testWidgets("an error Flutter marks silent isn't sent", (_) async {
    withHandlers(
      () => FlutterError.onError!(
        FlutterErrorDetails(exception: Exception(_private), silent: true),
      ),
    );
    expect(reports.all, isEmpty);
  });

  testWidgets('an error nobody awaited is sent, not fatal', (_) async {
    withHandlers(
      () => PlatformDispatcher.instance.onError!(
        const FormatException('bad', _private),
        StackTrace.current,
      ),
    );
    expect(reports.all, [
      (type: 'FormatException', source: 'async', fatal: false),
    ]);
  });

  testWidgets("a bloc's error is sent, not fatal", (_) async {
    withHandlers(() {
      final counter = _Counter()..fail(ArgumentError(_private));
      addTearDown(counter.close);
    });
    expect(reports.all, [
      (type: 'ArgumentError', source: 'bloc', fatal: false),
    ]);
  });

  testWidgets('reporting stays quiet without Firebase', (tester) async {
    // No Firebase in tests: starting and recording must not throw, or
    // the error handler would report its own failure, for ever.
    FirebaseCrashReporter()
      ..start()
      ..record(type: 'X', stack: null, source: 'async', fatal: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
