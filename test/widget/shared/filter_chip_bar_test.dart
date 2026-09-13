import 'package:cloud_lms/shared/widgets/filter_chip_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppFilterChipBar shows every option and reports selection', (tester) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFilterChipBar<String>(
            options: const ['All', 'Pending', 'Paid'],
            selected: 'All',
            labelBuilder: (option) => option,
            onSelected: (option) => selected = option,
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);

    await tester.tap(find.text('Paid'));
    await tester.pump();

    expect(selected, 'Paid');
  });

  testWidgets('AppFilterChipBar renders an optional count badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFilterChipBar<String>(
            options: const ['All', 'Academic'],
            selected: 'All',
            labelBuilder: (option) => option,
            countBuilder: (option) => option == 'All' ? 12 : 5,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('All 12'), findsOneWidget);
    expect(find.text('Academic 5'), findsOneWidget);
  });
}
