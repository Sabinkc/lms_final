import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// Summary banner at the top of a list screen: a tinted gradient card with a
/// round icon, a bold title, a one-line description and an optional
/// highlighted figure on the right ("Total 22"). Promoted from the Notices
/// "Stay Informed" banner so every module's list opens the same way.
class PageHeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  /// Optional figure shown in the white badge on the right.
  final String? figure;
  final String figureLabel;

  /// Optional extra content under the title row (e.g. a progress bar).
  final Widget? footer;

  const PageHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = AppColors.primary,
    this.figure,
    this.figureLabel = 'Total',
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), AppColors.primary.withValues(alpha: 0.06)]),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: dark ? theme.colorScheme.onSurface : Color.lerp(color, Colors.black, 0.45),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (figure != null) ...[
                const SizedBox(width: 10),
                Container(
                  constraints: const BoxConstraints(minWidth: 64),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(figureLabel, style: theme.textTheme.labelSmall?.copyWith(color: color)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          figure!,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }
}
