/// Which build of the app is running.
enum AppFlavor {
  /// Local work against the Prism mock or a local backend.
  development,

  /// Pre-release testing.
  staging,

  /// Real users.
  production,
}

/// Settings that differ between flavors. Built once in each `main_*.dart`.
class AppConfig {
  const new({required this.flavor, required this.apiBaseUrl});

  /// Development: the API from `--dart-define=API_BASE_URL=...`, or the
  /// Prism mock on the host machine (10.0.2.2 is the host from the Android
  /// emulator).
  factory development() => const AppConfig(
    flavor: AppFlavor.development,
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:4010',
    ),
  );

  factory staging() => const AppConfig(
    flavor: AppFlavor.staging,
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://solacliq.markcliq.com/api/v1',
    ),
  );

  factory production() => const AppConfig(
    flavor: AppFlavor.production,
    apiBaseUrl: 'https://solacliq.markcliq.com/api/v1',
  );

  final AppFlavor flavor;

  /// Base URL of the API, including `/api/v1`.
  final String apiBaseUrl;

  /// Development-only tools, such as the component gallery.
  bool get showDevTools => flavor == AppFlavor.development;
}
