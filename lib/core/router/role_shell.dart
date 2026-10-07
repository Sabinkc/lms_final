import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/models/app_role.dart';
import '../dashboard/role_dashboard_config.dart';
import '../theme/app_colors.dart';

/// The persistent bottom-nav chrome for a role's shell, driven by
/// `go_router`'s [StatefulNavigationShell]. One widget, reused by all 4
/// `StatefulShellRoute`s in `app_router.dart` rather than duplicated per
/// role.
///
/// Deliberately has **no `AppBar` of its own** — several of the screens
/// promoted into a tab (e.g. `AdminFeesScreen`) already have their own
/// `AppBar` with real per-screen actions (export, payment review, ...);
/// wrapping them in a second outer `AppBar` here would either stack two
/// bars or force stripping those actions out of already-built, tested
/// screens, which is out of scope for a foundation/theme pass. Each role's
/// Home screen and `MoreScreen` — the two tabs that don't already have an
/// `AppBar` — carry their own instead.
class RoleShell extends StatelessWidget {
  final AppRole role;
  final StatefulNavigationShell navigationShell;

  const RoleShell({super.key, required this.role, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final config = RoleDashboardConfig.forRole(role);
    // Matches every role's Home screen/MoreScreen: Stitch's own bottom-nav
    // mockups use the same uniform primary-container green active-state
    // across every role, not a per-role tint.
    final accent = AppColors.primary;
    final index = navigationShell.currentIndex;

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      for (final tab in config.navTabs) NavigationDestination(icon: Icon(tab.icon), label: tab.label),
      const NavigationDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view_rounded),
        label: 'More',
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: navigationShell.goBranch,
        indicatorColor: accent.withValues(alpha: 0.16),
        destinations: destinations,
      ),
    );
  }
}
