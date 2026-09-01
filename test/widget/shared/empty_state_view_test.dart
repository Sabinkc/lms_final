import 'package:cloud_lms/shared/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the message and an optional action button', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            message: 'No notices yet.',
            actionLabel: 'Create notice',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No notices yet.'), findsOneWidget);

    await tester.tap(find.text('Create notice'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
