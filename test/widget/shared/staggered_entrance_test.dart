import 'package:cloud_lms/shared/widgets/staggered_entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _opacityOf(WidgetTester tester, String text) => tester
    .widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first)
    .opacity;

Widget _list(List<String> items, {bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: const Size(400, 800), disableAnimations: reduceMotion),
        child: Scaffold(
          body: ListView(children: [for (final i in items) StaggeredEntrance(child: SizedBox(height: 80, child: Text(i)))]),
        ),
      ),
    );

void main() {
  testWidgets('cards fade in, the lower ones after the upper ones, and end fully visible', (tester) async {
    await tester.pumpWidget(_list(['A', 'B', 'C', 'D', 'E', 'F']));
    await tester.pump(); // post-frame start
    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacityOf(tester, 'A'), greaterThan(_opacityOf(tester, 'F')));
    await tester.pumpAndSettle();
    for (final i in ['A', 'B', 'C', 'D', 'E', 'F']) {
      expect(_opacityOf(tester, i), 1);
    }
  });

  testWidgets('cards added after the first moments appear without animating', (tester) async {
    await tester.pumpWidget(_list(['A']));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(_list(['A', 'B']));
    await tester.pump();
    await tester.pump();
    expect(_opacityOf(tester, 'B'), 1);
  });

  testWidgets('reduced motion shows cards straight away', (tester) async {
    await tester.pumpWidget(_list(['A'], reduceMotion: true));
    await tester.pump();
    await tester.pump();
    expect(_opacityOf(tester, 'A'), 1);
  });
}
