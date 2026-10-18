import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/health/health.dart';

import '../helpers/helpers.dart';

void main() {
  late MockHealthRepository repository;
  const report = HealthReport(databaseOk: true, version: '0.1.0');

  setUp(() {
    repository = MockHealthRepository();
  });

  void stubFetch(Future<HealthReport> Function() answer) {
    when(() => repository.fetch(cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) => answer());
  }

  group(HealthCubit, () {
    test('starts checking', () {
      expect(HealthCubit(repository).state, const HealthChecking());
    });

    blocTest<HealthCubit, HealthState>(
      'emits loaded when the API answers',
      setUp: () => stubFetch(() async => report),
      build: () => HealthCubit(repository),
      act: (cubit) => cubit.check(),
      expect: () => const [HealthChecking(), HealthLoaded(report)],
    );

    blocTest<HealthCubit, HealthState>(
      'emits unreachable when the API cannot be reached',
      setUp: () =>
          stubFetch(() => Future.error(const HealthUnreachableException())),
      build: () => HealthCubit(repository),
      act: (cubit) => cubit.check(),
      expect: () => const [HealthChecking(), HealthUnreachable()],
    );

    test('close cancels the request in flight and emits nothing', () async {
      final started = Completer<CancelToken>();
      final never = Completer<HealthReport>();
      when(() => repository.fetch(cancelToken: any(named: 'cancelToken')))
          .thenAnswer((invocation) {
            started.complete(
              invocation.namedArguments[#cancelToken] as CancelToken,
            );
            return never.future;
          });
      final cubit = HealthCubit(repository);
      final states = <HealthState>[];
      final sub = cubit.stream.listen(states.add);
      unawaited(cubit.check());
      final token = await started.future;
      await cubit.close();
      expect(token.isCancelled, isTrue);
      never.complete(report);
      await Future<void>.delayed(Duration.zero);
      expect(states, const [HealthChecking()]);
      await sub.cancel();
    });

    test('a new check cancels the previous one', () async {
      final tokens = <CancelToken>[];
      final first = Completer<HealthReport>();
      var calls = 0;
      when(() => repository.fetch(cancelToken: any(named: 'cancelToken')))
          .thenAnswer((invocation) {
            tokens.add(invocation.namedArguments[#cancelToken] as CancelToken);
            calls++;
            return calls == 1 ? first.future : Future.value(report);
          });
      final cubit = HealthCubit(repository);
      unawaited(cubit.check());
      await cubit.check();
      expect(tokens.first.isCancelled, isTrue);
      expect(cubit.state, const HealthLoaded(report));
      await cubit.close();
    });
  });
}
