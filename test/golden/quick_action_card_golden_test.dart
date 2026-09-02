import 'package:cloud_lms/shared/widgets/quick_action_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

/// `QuickActionCard`/`QuickActionTile` are the building blocks for every
/// role dashboard's Home grid and More list (added in the 2026-09-01 UI
/// modernization pass, see `docs/production_roadmap.md`) — a regression
/// here would silently affect all 4 role dashboards, same reasoning as
/// `shared_widgets_golden_test.dart`'s coverage of the loading/error/empty
/// trio.
void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('QuickActionCard ($suffix)', (tester) async {
      await pumpForGolden(
        tester,
        brightness: brightness,
        surfaceSize: const Size(200, 160),
        child: QuickActionCard(icon: Icons.event_available_outlined, label: 'Attendance', onTap: () {}),
      );
      await expectLater(find.byType(QuickActionCard), matchesGoldenFile('goldens/quick_action_card_$suffix.png'));
    });

    testWidgets('QuickActionCard with a custom accent color ($suffix)', (tester) async {
      await pumpForGolden(
        tester,
        brightness: brightness,
        surfaceSize: const Size(200, 160),
        child: QuickActionCard(
          icon: Icons.payments_outlined,
          label: 'Fees',
          color: const Color(0xFFD97706),
          onTap: () {},
        ),
      );
      await expectLater(
        find.byType(QuickActionCard),
        matchesGoldenFile('goldens/quick_action_card_accent_$suffix.png'),
      );
    });

    testWidgets('QuickActionTile ($suffix)', (tester) async {
      await pumpForGolden(
        tester,
        brightness: brightness,
        surfaceSize: const Size(320, 72),
        child: QuickActionTile(icon: Icons.campaign_outlined, label: 'Notices', onTap: () {}),
      );
      await expectLater(find.byType(QuickActionTile), matchesGoldenFile('goldens/quick_action_tile_$suffix.png'));
    });
  }
}
