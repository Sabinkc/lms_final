import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// A gradient greeting banner for role Home screens — "Good Morning, {name}"
/// + a one-line subtitle, tinted with the viewer's role accent. Mirrors the
/// Stitch "Verdant Scholar" mockups' hero-card pattern (see
/// `docs/stitch_screens/cloudslms_*_home_dashboard*`), built from this app's
/// own confirmed (not Stitch's invented) brand tokens — role accent color,
/// existing [AppRadius]/[AppSpacing] scale.
class HeroBanner extends StatelessWidget {
  final String greeting;
  final String name;
  final String subtitle;
  final Color color;
  final IconData? trailingIcon;

  const HeroBanner({
    super.key,
    required this.greeting,
    required this.name,
    required this.subtitle,
    required this.color,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final onColor = Colors.white;
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
        ),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: onColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: onColor, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onColor.withValues(alpha: 0.9)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: onColor.withValues(alpha: 0.16), shape: BoxShape.circle),
              child: Icon(trailingIcon, color: onColor, size: 28),
            ),
          ],
        ],
      ),
    );
  }
}
