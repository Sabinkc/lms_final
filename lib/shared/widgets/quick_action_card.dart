import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import 'press_scale.dart';

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

  const QuickActionCard({super.key, required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;

    return PressScale(
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: tint.withValues(alpha: 0.14), shape: BoxShape.circle),
                  child: Icon(icon, color: tint, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
  final String? subtitle;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;

    return PressScale(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: tint.withValues(alpha: 0.14), borderRadius: AppRadius.card),
          child: Icon(icon, color: tint, size: 20),
        ),
        // maxLines+ellipsis on both — the More screen's paired 2-column
        // groups only give each tile ~150-170dp of width, where a full
        // label like "Attendance Corrections" wrapped into a jumbled
        // one-letter-per-line stack instead of a clean line (found live on
        // device, not just a narrow-test-width theoretical). Truncating is
        // the safe default at any column width; the standalone (non-paired)
        // usage doesn't need the room either since the label is already
        // short by design.
        title: Text(label, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
