import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'progress_overlay.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/theme/readable_color.dart';

/// The branded Home-screen `AppBar` — logo/wordmark/tagline, a hamburger
/// that opens that role's More screen, a notification bell with an unread
/// badge, and an avatar+initials dropdown for Log out. Promoted from
/// `AdminHomeScreen`'s private `_AdminAppBar` so every role's Home screen
/// shares one app bar instead of reimplementing it per role.
class BrandHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String initials;
  final int unreadCount;

  /// The role's More route, opened by the leading hamburger button. Pass
  /// `null` when this bar is used *on* the More screen itself (nowhere
  /// further to hamburger into) — the leading button is omitted rather than
  /// shown disabled or pointing at the current screen.
  final String? moreRoute;

  const BrandHomeAppBar({super.key, required this.initials, required this.unreadCount, this.moreRoute});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      // No hamburger on the More screen — fall back to the default gutter so
      // the logo doesn't sit flush against the screen edge.
      titleSpacing: moreRoute == null ? NavigationToolbar.kMiddleSpacing : 0,
      leading: moreRoute == null
          ? null
          : IconButton(tooltip: 'More', icon: const Icon(Icons.menu), onPressed: () => context.push(moreRoute!)),
      automaticallyImplyLeading: moreRoute != null,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.asset('assets/icon/app_icon.png', width: 32, height: 32, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(
                        text: 'Clouds',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      TextSpan(
                        text: 'LMS',
                        style: TextStyle(color: context.readable(AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Learn • Manage • Grow',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        BrandNotificationBell(unreadCount: unreadCount),
        BrandAccountMenu(initials: initials),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}

/// Notification bell with an unread badge — shared by [BrandHomeAppBar]
/// and [BrandAppBar] so both bars stay visually identical.
class BrandNotificationBell extends StatelessWidget {
  final int unreadCount;

  const BrandNotificationBell({super.key, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

/// Avatar+initials dropdown with Log out — shared by [BrandHomeAppBar] and
/// [BrandAppBar].
class BrandAccountMenu extends StatelessWidget {
  final String initials;

  const BrandAccountMenu({super.key, required this.initials});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      onSelected: (value) {
        if (value == 'logout') runWithProgress(context, context.read<AuthProvider>().logout, message: 'Logging out…');
      },
      itemBuilder: (context) => const [PopupMenuItem(value: 'logout', child: Text('Log out'))],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
