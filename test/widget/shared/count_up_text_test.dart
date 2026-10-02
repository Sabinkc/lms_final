import 'package:cloud_lms/shared/widgets/count_up_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(String value, {bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: CountUpText(value)),
      ),
    );

void main() {
  testWidgets('counts up from 0 and lands exactly on the value', (tester) async {
    await tester.pumpWidget(_wrap('412'));
    expect(find.text('0'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    final midway = int.parse((tester.widget<Text>(find.byType(Text))).data!);
    expect(midway, inExclusiveRange(0, 412));
    await tester.pumpAndSettle();
    expect(find.text('412'), findsOneWidget);
  });

  testWidgets('keeps percent suffix and rupee grouping while counting', (tester) async {
    await tester.pumpWidget(_wrap('92%'));
    await tester.pumpAndSettle();
    expect(find.text('92%'), findsOneWidget);

    await tester.pumpWidget(_wrap('Rs. 24,80,000'));
    await tester.pump(const Duration(milliseconds: 200));
    expect((tester.widget<Text>(find.byType(Text))).data, startsWith('Rs. '));
    await tester.pumpAndSettle();
    expect(find.text('Rs. 24,80,000'), findsOneWidget);
  });

  testWidgets('leaves non-number text alone', (tester) async {
    for (final value in ['—', '10:00 AM', '2026-10-15', 'Class 10']) {
      await tester.pumpWidget(_wrap(value));
      expect(find.text(value), findsOneWidget);
    }
  });

  testWidgets('shows the final value straight away when reduce motion is on', (tester) async {
    await tester.pumpWidget(_wrap('412', reduceMotion: true));
    expect(find.text('412'), findsOneWidget);
  });
}
