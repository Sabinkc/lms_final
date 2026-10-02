import 'package:cloud_lms/shared/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatCard shows its icon, value, and label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(icon: Icons.people_outline, value: '128', label: 'Total Students'),
        ),
      ),
    );
    await tester.pumpAndSettle(); // let the count-up finish

    expect(find.byIcon(Icons.people_outline), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('Total Students'), findsOneWidget);
  });

  testWidgets('StatCardRow lays out every card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCardRow(cards: [
            StatCard(icon: Icons.people_outline, value: '128', label: 'Students'),
            StatCard(icon: Icons.check_circle_outline, value: '93%', label: 'Present'),
            StatCard(icon: Icons.payments_outlined, value: 'Rs 5,600', label: 'Pending'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle(); // let the count-up finish

    expect(find.text('128'), findsOneWidget);
    expect(find.text('93%'), findsOneWidget);
    expect(find.text('Rs 5,600'), findsOneWidget);
  });

  testWidgets('StatCard shows a trend badge when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(icon: Icons.people_outline, value: '128', label: 'Total Students', trend: '+5%'),
        ),
      ),
    );
    await tester.pumpAndSettle(); // let the count-up finish

    expect(find.text('+5%'), findsOneWidget);
  });

  testWidgets('StatCard shows a progress ring with rounded percentage when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(icon: Icons.people_outline, value: '1,120', label: 'Present Today', progress: 0.93),
        ),
      ),
    );
    await tester.pumpAndSettle(); // let the count-up finish

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('93'), findsOneWidget);
  });
}
