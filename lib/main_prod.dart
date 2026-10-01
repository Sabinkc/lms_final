import 'bootstrap.dart';
import 'core/config/env.dart';

/// `flutter build apk -t lib/main_prod.dart --release`
/// `BASE_URL` defaults to [EnvConfig.productionBaseUrl]; override with
/// `--dart-define=BASE_URL=...` if needed. Verbose logging is forced off regardless of any flag
/// (see [EnvConfig.enableLogging]).
Future<void> main() async {
  const baseUrl = String.fromEnvironment('BASE_URL', defaultValue: EnvConfig.productionBaseUrl);

  await bootstrap(
    const EnvConfig(
      environment: AppEnvironment.prod,
      baseUrl: baseUrl,
      verboseLogging: false,
    ),
  );
}
