import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/tasks/view/capture_problems.dart';

void main() {
  group(CaptureProblems, () {
    test('a problem clears once that side works again', () {
      // Location was off; the person switched it on in settings.
      final problems = CaptureProblems()..location = CaptureProblem.locationOff;
      expect(problems.current, CaptureProblem.locationOff);
      problems.location = null;
      expect(problems.current, isNull);
    });

    test("the camera's problem shows first, then location's", () {
      final problems = CaptureProblems()
        ..camera = CaptureProblem.cameraDenied
        ..location = CaptureProblem.locationDenied;
      expect(problems.current, CaptureProblem.cameraDenied);
      // Allowing the camera reveals the location problem still there.
      problems.camera = null;
      expect(problems.current, CaptureProblem.locationDenied);
    });

    test('one side working leaves the other side alone', () {
      final problems = CaptureProblems()
        ..camera = CaptureProblem.noCamera
        ..location = null;
      expect(problems.current, CaptureProblem.noCamera);
    });
  });
}
