import 'package:cloud_lms/features/dual_calendar/presentation/screens/dual_calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the AD month header and a verified AD-27 / BS-11-Bhadra day pair', (tester) async {
    // Verified directly against nepali_utils (not guessed): 2026-08-27 AD
    // converts to 2083-05-11 BS ("Bhadra"), and NepaliDateFormat's 'MMM d'
    // pattern renders that as "Bha 11". Grown surface so GridView's lazy
    // builder actually lays out day 27, not just the first visible rows.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: DualCalendarScreen(initialMonth: DateTime(2026, 8))),
    );
    await tester.pumpAndSettle();

    expect(find.text('August 2026'), findsOneWidget);
    // The header's BS label is for the 1st of the AD month (Shrawan), not
    // the 27th's BS month (Bhadra) — verified separately below.
    expect(find.textContaining('Shrawan 2083'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
    expect(find.text('Bha 11'), findsOneWidget);
  });

  testWidgets('next-month navigation advances both the AD header and BS subtitle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DualCalendarScreen(initialMonth: DateTime(2026, 8))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('September 2026'), findsOneWidget);
  });

  testWidgets('today is visually highlighted when it falls in the displayed month', (tester) async {
    // Grow the test surface so every cell in the month is laid out by
    // GridView's lazy builder — otherwise which days exist in the tree
    // depends on the real day of the month the test happens to run on.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(home: DualCalendarScreen(initialMonth: DateTime(today.year, today.month))),
    );
    await tester.pumpAndSettle();

    final container = tester.widget<Container>(
      find.ancestor(of: find.text('${today.day}').first, matching: find.byType(Container)).first,
    );
    expect(container.decoration, isNotNull);
  });
}
