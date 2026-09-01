import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

/// A tappable icon+label card — the building block for the role Home
/// screens' quick-actions grid and the More screen's destination list.
/// Replaces the flat `FilledButton` wall the old `PlaceholderScreen`
/// dashboards used.
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Tint for the icon/background; defaults to the theme's primary color.
  final Color? color;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: AppRadius.card,
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single row-style variant used for the More screen's grouped list,
/// where a compact grid reads worse than a scannable list.
class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.14),
          borderRadius: AppRadius.card,
        ),
        child: Icon(icon, color: tint, size: 20),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
