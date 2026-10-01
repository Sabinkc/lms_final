import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

/// A pastel-background, solid-icon-chip tile for a role Home screen's
/// quick-actions grid — visually distinct from the uniform-tint
/// [QuickActionCard] this replaced, matching the "Verdant Scholar" photo-hero
/// reference design's colorful-portal-grid look. Promoted from
/// `AdminHomeScreen`'s private `_ColorfulActionTile` so Teacher/Student/
/// Parent Home can share the exact same tile instead of reimplementing it.
class ColorfulActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ColorfulActionTile({super.key, required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              // A single word too wide for the tile would otherwise be split
              // mid-word ("Assignment / s"); shrink it onto one line instead.
              if (label.contains(' '))
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: Theme.of(context).textTheme.labelMedium),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
