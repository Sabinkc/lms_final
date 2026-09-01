import 'bootstrap.dart';
import 'core/config/env.dart';

/// `flutter build apk -t lib/main_prod.dart --dart-define=BASE_URL=https://api.cloudslms.com --release`
/// `BASE_URL` is required — there is no localhost fallback for this
/// flavor. Verbose logging is forced off regardless of any flag
/// (see [EnvConfig.enableLogging]).
Future<void> main() async {
  const baseUrl = String.fromEnvironment('BASE_URL');
  assert(baseUrl.isNotEmpty, 'BASE_URL must be supplied via --dart-define for prod.');

  await bootstrap(
    const EnvConfig(
      environment: AppEnvironment.prod,
      baseUrl: baseUrl,
      verboseLogging: false,
    ),
  );
}
