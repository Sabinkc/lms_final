import 'package:cloud_lms/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `docs/production_roadmap.md` Phase K item 3 — golden/theme regression
/// tests for light/dark. These catch accidental theme-token regressions
/// (a widget silently losing its themed color/shape/elevation when
/// `AppTheme` or a shared widget changes), not real visual-design sign-off
/// — the actual look is still `ASSUMPTION`-based per `design_system.md`
/// until real screenshots/the web frontend are analyzed. Goldens get
/// regenerated (`flutter test --update-goldens`) whenever that happens.
///
/// Fixed surface size + device pixel ratio, restored after each test, so
/// goldens are stable across machines regardless of the host's real
/// display — same reasoning `tester.view.physicalSize` overrides always
/// need in golden tests.
Future<void> pumpForGolden(
  WidgetTester tester, {
  required Widget child,
  required Brightness brightness,
  Size surfaceSize = const Size(400, 400),
}) async {
  final view = tester.view;
  addTearDown(() {
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });
  view.devicePixelRatio = 1.0;
  view.physicalSize = surfaceSize;

  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      home: Scaffold(body: child),
    ),
  );
  // A fixed pump, not `pumpAndSettle` — some widgets under test (e.g.
  // `LoadingView`'s `CircularProgressIndicator`) animate indefinitely and
  // would never let `pumpAndSettle` return.
  await tester.pump(const Duration(milliseconds: 100));
}
