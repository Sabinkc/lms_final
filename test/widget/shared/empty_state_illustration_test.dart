import 'package:cloud_lms/shared/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the illustration with the screen icon as a badge, the message and the action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EmptyStateView(
          message: 'No notices yet',
          icon: Icons.campaign_outlined,
          actionLabel: 'Add Notice',
          onAction: () => tapped = true,
        ),
      ),
    ));
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
    expect(find.text('No notices yet'), findsOneWidget);
    await tester.tap(find.text('Add Notice'));
    expect(tapped, isTrue);
  });
}
