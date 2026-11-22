import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';

void main() {
  group(SubmitCubit, () {
    blocTest<SubmitCubit, SubmitState>(
      'success',
      build: SubmitCubit.new,
      act: (cubit) => cubit.submit(() async {}),
      expect: () => const [
        SubmitState(status: SubmitStatus.submitting),
        SubmitState(status: SubmitStatus.success),
      ],
    );

    blocTest<SubmitCubit, SubmitState>(
      'an AuthFailure becomes a failure state',
      build: SubmitCubit.new,
      act: (cubit) => cubit.submit(
        () => Future.error(const AuthFailure(AuthFailureCode.network)),
      ),
      expect: () => const [
        SubmitState(status: SubmitStatus.submitting),
        SubmitState(
          status: SubmitStatus.failure,
          failure: AuthFailureCode.network,
        ),
      ],
    );

    blocTest<SubmitCubit, SubmitState>(
      'ignores a second submit while one is running',
      build: SubmitCubit.new,
      act: (cubit) async {
        var calls = 0;
        final first = cubit.submit(() async => calls++);
        await cubit.submit(() async => calls++);
        await first;
        expect(calls, 1);
      },
      expect: () => const [
        SubmitState(status: SubmitStatus.submitting),
        SubmitState(status: SubmitStatus.success),
      ],
    );

    blocTest<SubmitCubit, SubmitState>(
      "an edit while sending doesn't let a second send start",
      build: SubmitCubit.new,
      act: (cubit) async {
        final sending = Completer<void>();
        var calls = 0;
        final first = cubit.submit(() {
          calls++;
          return sending.future;
        });
        cubit.reset();
        final second = cubit.submit(() async => calls++);
        sending.complete();
        await first;
        await second;
        expect(calls, 1);
      },
      expect: () => const [
        SubmitState(status: SubmitStatus.submitting),
        SubmitState(status: SubmitStatus.success),
      ],
    );

    blocTest<SubmitCubit, SubmitState>(
      'reset returns to idle',
      build: SubmitCubit.new,
      seed: () => const SubmitState(
        status: SubmitStatus.failure,
        failure: AuthFailureCode.unknown,
      ),
      act: (cubit) => cubit.reset(),
      expect: () => const [SubmitState()],
    );
  });
}
