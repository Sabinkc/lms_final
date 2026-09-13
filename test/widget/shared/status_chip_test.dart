import 'package:cloud_lms/shared/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppStatusChip renders its label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppStatusChip(label: 'Paid', color: Colors.green)),
      ),
    );

    expect(find.text('Paid'), findsOneWidget);
    expect(find.byType(Chip), findsOneWidget);
  });
}
