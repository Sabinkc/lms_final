import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Green gradient card + the real cropped photo from the user's reference
/// design (`assets/images/admin_hero_school.jpg`), faded into the gradient
/// on its left edge via a color overlay so the greeting text stays legible.
/// Promoted from `AdminHomeScreen`'s private `_AdminHeroBanner` so every
/// role's Home screen can share one photo-hero look, matching Stitch's own
/// mockups using the identical primary-container green across every role
/// rather than a per-role tint.
class PhotoHeroBanner extends StatelessWidget {
  final String greeting;
  final String name;
  final String subtitle;

  const PhotoHeroBanner({super.key, required this.greeting, required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.card,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/admin_hero_school.jpg', fit: BoxFit.cover),
            ),
            // Darkens the left ~70% (where the greeting text sits) down to
            // the base gradient's own tone, fading out toward the right so
            // the photo itself stays visible full-bleed rather than boxed
            // into a strip.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.primaryDark.withValues(alpha: 0.92),
                      AppColors.primary.withValues(alpha: 0.75),
                      AppColors.primary.withValues(alpha: 0.25),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
