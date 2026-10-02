import 'package:cloud_lms/features/fees/presentation/widgets/fee_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows how much of the fee is paid', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FeeProgressBar(paid: 4000, total: 10000, color: Colors.orange)),
    ));
    expect(find.text('Rs. 4,000 of Rs. 10,000 paid'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.4);
  });

  testWidgets('a zero-total fee shows an empty bar instead of dividing by zero', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FeeProgressBar(paid: 0, total: 0, color: Colors.orange)),
    ));
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0);
  });
}
