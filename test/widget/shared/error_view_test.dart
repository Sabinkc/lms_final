import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the exception message and invokes onRetry when tapped', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            error: const ServerException('Something broke'),
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Something broke'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });

  testWidgets('hides the retry button when onRetry is not provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ErrorView(error: NetworkException())),
      ),
    );

    expect(find.text('Retry'), findsNothing);
  });
}
