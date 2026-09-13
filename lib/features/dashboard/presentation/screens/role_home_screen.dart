import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/dashboard/role_dashboard_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/quick_action_card.dart';
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// The real per-role dashboard — replaces the old `PlaceholderScreen`
/// button wall. One generic widget configured per role via
/// `RoleDashboardConfig` rather than 4 near-duplicate files. Deliberately a
/// navigation/orientation surface, not a new analytics screen — it doesn't
/// fetch or display live stat numbers (that would need new provider/API
/// wiring, out of scope for this pass).
class RoleHomeScreen extends StatelessWidget {
  final AppRole role;

  const RoleHomeScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final config = RoleDashboardConfig.forRole(role);
    final accent = AppColors.roleColor(role);
    final user = context.watch<AuthProvider>().user;

    final quickActions = [...config.navTabs, ...config.homeHighlights];

    return Scaffold(
      appBar: AppBar(
        title: Text(config.homeTitle),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Greeting(name: user?.fullName, role: role, accent: accent),
            const SizedBox(height: AppSpacing.xl),
            Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.95,
              children: [
                for (final action in quickActions)
                  QuickActionCard(
                    icon: action.icon,
                    label: action.label,
                    color: accent,
                    onTap: () => context.push(action.route),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String? name;
  final AppRole role;
  final Color accent;

  const _Greeting({required this.name, required this.role, required this.accent});

  static String _timeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final roleLabel = switch (role) {
      AppRole.admin => 'Administrator',
      AppRole.teacher => 'Teacher',
      AppRole.student => 'Student',
      AppRole.parent => 'Parent',
    };
    final firstName = (name != null && name!.trim().isNotEmpty) ? name!.trim().split(' ').first : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: accent,
            child: Text(
              (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_timeOfDayGreeting()}${firstName != null ? ',' : ''}',
                  style: textTheme.bodyMedium,
                ),
                if (firstName != null)
                  Text(firstName, style: textTheme.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  "Here's what's happening today",
                  style: textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
