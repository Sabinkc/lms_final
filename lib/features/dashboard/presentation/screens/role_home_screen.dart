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
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.3,
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final roleLabel = switch (role) {
      AppRole.admin => 'Administrator',
      AppRole.teacher => 'Teacher',
      AppRole.student => 'Student',
      AppRole.parent => 'Parent',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: accent,
            child: Text(
              (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back${name != null && name!.isNotEmpty ? ',' : ''}', style: textTheme.bodyMedium),
                if (name != null && name!.isNotEmpty)
                  Text(name!, style: textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(roleLabel, style: textTheme.bodySmall?.copyWith(color: accent, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
