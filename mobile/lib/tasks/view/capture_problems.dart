/// Why the proof camera can't take a photo right now.
enum CaptureProblem { noCamera, cameraDenied, locationOff, locationDenied }

/// The camera's and the location's problems, kept apart so each clears
/// itself once that side works again (after a permission dialog, or
/// location switched on in settings). The camera's shows first.
class CaptureProblems {
  /// Set when the camera fails; null once it starts.
  CaptureProblem? camera;

  /// Set when location fails; null once a position arrives.
  CaptureProblem? location;

  /// The one to show, if any.
  CaptureProblem? get current => camera ?? location;
}
