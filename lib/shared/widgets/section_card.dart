import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/readable_color.dart';

/// A white rounded card with a tinted round icon, a bold title, an optional
/// trailing widget / "View All" link, then its content. Promoted from Class
/// Details' private `_SectionCard` for grouping related content on detail
/// and dashboard-like screens.
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onViewAll;
  final Widget? trailing;
  final Widget child;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.color = AppColors.primary,
    this.onViewAll,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, size: 20, color: context.readable(color)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                ?trailing,
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text('View All'), SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 16)],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
