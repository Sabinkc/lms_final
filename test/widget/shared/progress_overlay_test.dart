import 'dart:async';

import 'package:cloud_lms/shared/widgets/progress_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(void Function(BuildContext context) onPressed) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(onPressed: () => onPressed(context), child: const Text('Go')),
        ),
      ),
    );

void main() {
  testWidgets('shows a blocking spinner while the action runs, then closes and returns its result', (tester) async {
    final completer = Completer<bool>();
    Future<bool>? result;
    await tester.pumpWidget(_host((context) {
      result = runWithProgress(context, () => completer.future, message: 'Deleting…');
    }));

    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(find.text('Deleting…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Tapping outside must not dismiss it.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.text('Deleting…'), findsOneWidget);

    completer.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Deleting…'), findsNothing);
    expect(await result, isTrue);
    expect(find.text('Go'), findsOneWidget);
  });

  testWidgets('closes the spinner even when the action throws', (tester) async {
    Object? caught;
    await tester.pumpWidget(_host((context) {
      runWithProgress<void>(context, () async => throw StateError('boom')).catchError((Object e) => caught = e);
    }));

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(find.byType(ProgressDialog), findsNothing);
    expect(caught, isA<StateError>());
    expect(find.text('Go'), findsOneWidget);
  });
}
