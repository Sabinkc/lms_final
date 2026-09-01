import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/shared/widgets/empty_state_view.dart';
import 'package:cloud_lms/shared/widgets/error_view.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

/// Every feature screen's loading/error/empty state routes through one of
/// these three shared widgets (`docs/screens.md`'s stated convention) — a
/// regression here would silently affect every screen in the app, so these
/// are the highest-value golden coverage for the smallest number of files.
void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('LoadingView ($suffix)', (tester) async {
      await pumpForGolden(tester, brightness: brightness, child: const LoadingView(message: 'Loading...'));
      await expectLater(find.byType(LoadingView), matchesGoldenFile('goldens/loading_view_$suffix.png'));
    });

    testWidgets('ErrorView ($suffix)', (tester) async {
      await pumpForGolden(
        tester,
        brightness: brightness,
        child: ErrorView(error: const NetworkException('No internet connection'), onRetry: () {}),
      );
      await expectLater(find.byType(ErrorView), matchesGoldenFile('goldens/error_view_$suffix.png'));
    });

    testWidgets('EmptyStateView ($suffix)', (tester) async {
      await pumpForGolden(
        tester,
        brightness: brightness,
        child: const EmptyStateView(message: 'Nothing here yet', icon: Icons.inbox_outlined),
      );
      await expectLater(find.byType(EmptyStateView), matchesGoldenFile('goldens/empty_state_view_$suffix.png'));
    });
  }
}
