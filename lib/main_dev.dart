import 'bootstrap.dart';
import 'core/config/env.dart';

/// `flutter run -t lib/main_dev.dart --dart-define=BASE_URL=http://localhost:4000`
/// (docs/api_spec.md §1 confirms the backend's local default port is 4000).
Future<void> main() async {
  await bootstrap(
    const EnvConfig(
      environment: AppEnvironment.dev,
      baseUrl: String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:4000'),
      verboseLogging: true,
    ),
  );
}
