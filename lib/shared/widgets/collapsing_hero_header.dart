import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../utils/local_occasion.dart';

/// The role Home photo banner as a pinned sliver: full banner at the top of
/// the page, shrinking into a slim green "Good Morning, Name" bar as the
/// page scrolls, so Home keeps its header while the content gets the room.
/// Shows today's Bikram Sambat date, swaps the greeting for a festival
/// greeting on Dashain/Tihar/New Year, and tints the photo by time of day.
/// Use as the first sliver of a `CustomScrollView`.
class CollapsingHeroHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String subtitle;

  const CollapsingHeroHeader({super.key, required this.greeting, required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    // Taller when the user has large text on, so the banner never clips.
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeroDelegate(greeting: greeting, name: name, subtitle: subtitle, textScale: textScale),
    );
  }
}

class _HeroDelegate extends SliverPersistentHeaderDelegate {
  final String greeting;
  final String name;
  final String subtitle;
  final double textScale;

  _HeroDelegate({required this.greeting, required this.name, required this.subtitle, required this.textScale});

  @override
  double get maxExtent => 184 + (textScale - 1).clamp(0.0, 2.0) * 100;

  @override
  double get minExtent => 56 + (textScale - 1).clamp(0.0, 2.0) * 16;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final side = lerpDouble(AppSpacing.lg, 0, t)!;
    final textTheme = Theme.of(context).textTheme;
    const white = Colors.white;
    final now = DateTime.now();
    final shownGreeting = festivalGreeting(now) ?? greeting;
    final dateLine = '${_weekdays[now.weekday - 1]} · ${bsDateLabel(now)}';

    return Padding(
      padding: EdgeInsets.fromLTRB(side, 0, side, lerpDouble(AppSpacing.lg, 0, t)!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(lerpDouble(24, 0, t)!),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
            ),
            Opacity(
              opacity: 1 - t,
              child: Image.asset('assets/images/admin_hero_school.jpg', fit: BoxFit.cover),
            ),
            // Time of day: warm light in the morning, none in the afternoon,
            // a clay glow in the evening, deep slate at night.
            if (_timeTint(now.hour) case final tint?)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      tint.withValues(alpha: tint.a * (1 - t)),
                      tint.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            // Darkens the text side of the photo; fully green once collapsed.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDark.withValues(alpha: 0.92),
                    AppColors.primary.withValues(alpha: 0.75),
                    AppColors.primary.withValues(alpha: 0.25 + 0.75 * t),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: lerpDouble(AppSpacing.lg, 18, t)!),
              child: t < 0.6
                  ? Opacity(
                      opacity: (1 - t / 0.6).clamp(0.0, 1.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateLine,
                              style: textTheme.labelSmall?.copyWith(
                                color: white.withValues(alpha: 0.75),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shownGreeting,
                              style: textTheme.labelMedium?.copyWith(
                                color: white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineSmall?.copyWith(color: white, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width * 0.6,
                              child: Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(color: white.withValues(alpha: 0.9)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Opacity(
                      opacity: ((t - 0.6) / 0.4).clamp(0.0, 1.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$shownGreeting ',
                                style: TextStyle(color: white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: name,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(color: white),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_HeroDelegate old) =>
      old.greeting != greeting || old.name != name || old.subtitle != subtitle || old.textScale != textScale;
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

Color? _timeTint(int hour) => switch (hour) {
  >= 5 && < 11 => AppColors.ochre.withValues(alpha: 0.35),
  >= 11 && < 17 => null,
  >= 17 && < 20 => AppColors.clay.withValues(alpha: 0.4),
  _ => AppColors.slate.withValues(alpha: 0.55),
};
