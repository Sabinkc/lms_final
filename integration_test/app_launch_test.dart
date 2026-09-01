import 'package:cloud_lms/app.dart';
import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/di/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Real-device/simulator smoke test — proves the whole assembled app
/// (DI → providers → router → theme) boots without throwing. Run with:
/// `flutter test integration_test/app_launch_test.dart`
///
/// Deliberately the only integration test in this foundation pass — one
/// per feature gets added as that feature is built, following this same
/// "does it boot and reach the expected screen" shape.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to the login screen when no session is stored', (tester) async {
    await setupServiceLocator(
      const EnvConfig(
        environment: AppEnvironment.dev,
        baseUrl: 'http://localhost:4000',
        verboseLogging: false,
      ),
    );

    await tester.pumpWidget(const CloudsLmsApp());
    await tester.pumpAndSettle();

    expect(find.text('CloudsLMS'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);

    await resetServiceLocator();
  });
}
