import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

/// One small widget exercising the handful of `ThemeData.copyWith`
/// overrides `AppTheme` actually makes (card shape/elevation/color, button
/// shapes, input border, app bar) — a broader net than the per-shared-widget
/// goldens in `shared_widgets_golden_test.dart`, catching a regression in
/// any one of those overrides even if no shared widget happens to exercise
/// it yet.
class _ThemeKitchenSink extends StatelessWidget {
  const _ThemeKitchenSink();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBar(title: const Text('Kitchen Sink')),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Card body', style: Theme.of(context).textTheme.bodyMedium))),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Filled')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              const SizedBox(height: 8),
              const TextField(decoration: InputDecoration(labelText: 'Label')),
            ],
          ),
        ),
      ],
    );
  }
}

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('Theme kitchen sink ($suffix)', (tester) async {
      await pumpForGolden(
        tester,
        brightness: brightness,
        surfaceSize: const Size(400, 500),
        child: const _ThemeKitchenSink(),
      );
      await expectLater(find.byType(_ThemeKitchenSink), matchesGoldenFile('goldens/theme_kitchen_sink_$suffix.png'));
    });
  }
}
