import 'bootstrap.dart';
import 'core/config/env.dart';

/// Default entrypoint — reads `--dart-define`s directly (see [EnvConfig]).
/// `flutter run` with no flags behaves like [main_dev]. Prefer the
/// explicit `main_dev.dart` / `main_staging.dart` / `main_prod.dart`
/// entrypoints for anything beyond local `flutter run`, so a build command
/// can't accidentally omit `--dart-define=ENV=prod` and ship a dev config.
Future<void> main() async {
  await bootstrap(EnvConfig.fromDartDefine());
}
