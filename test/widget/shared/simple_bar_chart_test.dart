import 'package:cloud_lms/shared/widgets/simple_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SimpleBarChart renders one bar per value with its label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SimpleBarChart(values: const [10, 20, 5], labels: const ['Apr', 'May', 'Jun']),
        ),
      ),
    );

    expect(find.text('Apr'), findsOneWidget);
    expect(find.text('May'), findsOneWidget);
    expect(find.text('Jun'), findsOneWidget);
  });

  testWidgets('SimpleBarChart handles an all-zero series without dividing by zero', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SimpleBarChart(values: const [0, 0], labels: const ['Jan', 'Feb']),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Jan'), findsOneWidget);
  });
}
