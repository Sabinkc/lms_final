import 'package:cloud_lms/shared/widgets/success_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the tick and message with a vibration, then closes by itself', (tester) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
      return null;
    });

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showSuccess(context, title: 'Attendance submitted', subtitle: 'Class 10 · A'),
          child: const Text('Go'),
        ),
      ),
    ));
    await tester.tap(find.text('Go'));
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Attendance submitted'), findsOneWidget);
    expect(find.text('Class 10 · A'), findsOneWidget);
    expect(haptics, ['HapticFeedbackType.mediumImpact']);

    await tester.pumpAndSettle();
    expect(find.text('Attendance submitted'), findsNothing);
  });
}
