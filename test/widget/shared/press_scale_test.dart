import 'package:cloud_lms/shared/widgets/press_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _scale(WidgetTester tester) => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

Widget _wrap({bool reduceMotion = false, VoidCallback? onTap}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(
            child: PressScale(child: ElevatedButton(onPressed: onTap ?? () {}, child: const Text('Tile'))),
          ),
        ),
      ),
    );

void main() {
  testWidgets('sinks while pressed, springs back on release, and still taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(onTap: () => taps++));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Tile')));
    await tester.pump();
    expect(_scale(tester), lessThan(1));
    await gesture.up();
    await tester.pump();
    expect(_scale(tester), 1);
    expect(taps, 1);
  });

  testWidgets('springs back when the finger moves into a scroll', (tester) async {
    await tester.pumpWidget(_wrap());
    final gesture = await tester.startGesture(tester.getCenter(find.text('Tile')));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(_scale(tester), 1);
    await gesture.up();
  });

  testWidgets('does nothing when reduce motion is on', (tester) async {
    await tester.pumpWidget(_wrap(reduceMotion: true));
    expect(find.byType(AnimatedScale), findsNothing);
  });
}
