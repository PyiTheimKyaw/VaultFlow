/// Build-time configuration, injected with `--dart-define-from-file`:
///
///   flutter run --dart-define-from-file=env/dev.json
///   flutter build web --dart-define-from-file=env/prod.json
///
/// Every value has a development default so a plain `flutter run` works.
abstract final class AppEnvironment {
  static const String name = String.fromEnvironment(
    'VAULTFLOW_ENV',
    defaultValue: 'dev',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'VAULTFLOW_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Empty disables crash reporting.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static const String appVersion = String.fromEnvironment(
    'VAULTFLOW_VERSION',
    defaultValue: '0.7.0',
  );

  static bool get isProduction => name == 'prod';
  static bool get crashReportingEnabled => sentryDsn.isNotEmpty;
}
