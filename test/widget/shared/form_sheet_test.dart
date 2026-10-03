import 'package:cloud_lms/core/theme/app_theme.dart';
import 'package:cloud_lms/shared/widgets/form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showFormSheet<void>(
              context: context,
              builder: (sheetContext) => FormSheet(
                title: const Text('Add Thing'),
                content: Column(children: [for (var i = 0; i < 4; i++) TextFormField()]),
                actions: [
                  TextButton(onPressed: () => Navigator.of(sheetContext).pop(), child: const Text('Cancel')),
                  FilledButton(onPressed: () {}, child: const Text('Save')),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows title, fields and full-width actions; Cancel closes it', (tester) async {
    await openSheet(tester);

    expect(find.text('Add Thing'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    final cancel = tester.getSize(find.widgetWithText(TextButton, 'Cancel'));
    final save = tester.getSize(find.widgetWithText(FilledButton, 'Save'));
    expect(cancel.width, save.width);
    expect(save.height, 50);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(FormSheet), findsNothing);
  });

  testWidgets('buttons stay above the keyboard', (tester) async {
    await openSheet(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final keyboardTop = screenHeight - 900 / tester.view.devicePixelRatio;
    expect(tester.getBottomLeft(find.text('Save')).dy, lessThan(keyboardTop));
  });
}
