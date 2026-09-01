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

  const EnvConfig({
    required this.environment,
    required this.baseUrl,
    required this.verboseLogging,
  });

  /// The confirmed backend has no version prefix (docs/api_spec.md §1) —
  /// this constant exists so a future `/v1`-style change is a one-line diff.
  static const String apiPrefix = '/api';

  bool get enableLogging => verboseLogging && environment != AppEnvironment.prod;

  bool get isProd => environment == AppEnvironment.prod;

  /// Reads the `--dart-define`s an entrypoint supplied. Falls back to local
  /// backend defaults (docs/api_spec.md §1: `PORT` env var defaults to
  /// `4000` in the backend repo) only for [AppEnvironment.dev], so a
  /// misconfigured staging/prod build fails loudly instead of silently
  /// talking to localhost.
  factory EnvConfig.fromDartDefine() {
    const envName = String.fromEnvironment('ENV', defaultValue: 'dev');
    final environment = AppEnvironment.values.firstWhere(
      (e) => e.name == envName,
      orElse: () => AppEnvironment.dev,
    );

    const definedBaseUrl = String.fromEnvironment('BASE_URL');
    final baseUrl = definedBaseUrl.isNotEmpty
        ? definedBaseUrl
        : (environment == AppEnvironment.dev
            ? 'http://localhost:4000'
            : throw StateError(
                'BASE_URL must be supplied via --dart-define for the '
                '"$envName" environment — refusing to fall back to localhost.',
              ));

    const verbose = bool.fromEnvironment('VERBOSE_LOGGING', defaultValue: true);

    return EnvConfig(
      environment: environment,
      baseUrl: baseUrl,
      verboseLogging: verbose,
    );
  }

  @override
  String toString() =>
      'EnvConfig(environment: ${environment.name}, baseUrl: $baseUrl, '
      'enableLogging: $enableLogging)';
}
