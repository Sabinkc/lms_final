/// Compile-time environment configuration.
///
/// Values are injected via `--dart-define` at build time (see the three
/// entrypoints in `lib/main_dev.dart`, `lib/main_staging.dart`,
/// `lib/main_prod.dart`) — never hardcoded and never read at runtime from
/// a `.env` file, so a release build can't accidentally ship a dev URL.
library;

enum AppEnvironment { dev, staging, prod }

class EnvConfig {
  final AppEnvironment environment;

  /// Backend origin, no trailing slash. Confirmed API prefix is `/api`
  /// (docs/api_spec.md §1) — that prefix is added by [ApiClient], not here.
  final String baseUrl;

  /// Verbose request/response logging. Forced off for [AppEnvironment.prod]
  /// regardless of the flag below, as a safety net (see [enableLogging]).
  final bool verboseLogging;

  const EnvConfig({required this.environment, required this.baseUrl, required this.verboseLogging});

  /// The confirmed backend has no version prefix (docs/api_spec.md §1) —
  /// this constant exists so a future `/v1`-style change is a one-line diff.
  static const String apiPrefix = '/api';

  /// Live production backend. Used whenever no `BASE_URL` dart-define is
  /// supplied, so a plain `flutter run` / `flutter build` talks to prod.
  static const String productionBaseUrl = 'https://backend.cloudslms.com';

  bool get enableLogging => verboseLogging && environment != AppEnvironment.prod;

  bool get isProd => environment == AppEnvironment.prod;

  /// Reads the `--dart-define`s an entrypoint supplied. `BASE_URL` falls
  /// back to [productionBaseUrl]; pass
  /// `--dart-define=BASE_URL=http://localhost:4000` to hit a local backend.
  factory EnvConfig.fromDartDefine() {
    const envName = String.fromEnvironment('ENV', defaultValue: 'dev');
    final environment = AppEnvironment.values.firstWhere((e) => e.name == envName, orElse: () => AppEnvironment.dev);

    const baseUrl = String.fromEnvironment('BASE_URL', defaultValue: productionBaseUrl);

    const verbose = bool.fromEnvironment('VERBOSE_LOGGING', defaultValue: true);

    return EnvConfig(environment: environment, baseUrl: baseUrl, verboseLogging: verbose);
  }

  @override
  String toString() =>
      'EnvConfig(environment: ${environment.name}, baseUrl: $baseUrl, '
      'enableLogging: $enableLogging)';
}
