import 'bootstrap.dart';
import 'core/config/env.dart';

/// `flutter run -t lib/main_staging.dart --dart-define=BASE_URL=https://staging.cloudslms.com`
/// `BASE_URL` is required for this flavor — there is no localhost fallback
/// (see [EnvConfig.fromDartDefine]'s doc comment for why).
Future<void> main() async {
  const baseUrl = String.fromEnvironment('BASE_URL');
  assert(baseUrl.isNotEmpty, 'BASE_URL must be supplied via --dart-define for staging.');

  await bootstrap(
    const EnvConfig(
      environment: AppEnvironment.staging,
      baseUrl: baseUrl,
      verboseLogging: true,
    ),
  );
}
