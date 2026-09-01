import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/dashboard/role_dashboard_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/quick_action_card.dart';
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// The catch-all destination list for whatever isn't a bottom-nav tab —
/// the modernized, exhaustive replacement for the old dashboards' flat
/// `FilledButton` wall. `RoleDashboardConfig.moreItems` is deliberately
/// exhaustive (everything the old dashboard linked to that isn't now a
/// nav tab), so nothing that used to be reachable becomes unreachable.
class MoreScreen extends StatelessWidget {
  final AppRole role;

  const MoreScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final config = RoleDashboardConfig.forRole(role);
    final accent = AppColors.roleColor(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
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
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: config.moreItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final action = config.moreItems[index];
          return QuickActionTile(
            icon: action.icon,
            label: action.label,
            color: accent,
            onTap: () => context.push(action.route),
          );
        },
      ),
    );
  }
}
