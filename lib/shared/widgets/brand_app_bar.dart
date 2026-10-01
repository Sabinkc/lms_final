import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../utils/initials.dart';
import 'brand_home_app_bar.dart';

/// The branded `AppBar` for every non-Home screen — same height, title
/// weight, notification bell and avatar menu as [BrandHomeAppBar], but with
/// the screen's own title in place of the wordmark. The logo shows only on
/// screens with no back button (bottom-nav tab roots), where it sits in the
/// same spot as on Home; pushed screens keep the back arrow instead, since
/// logo + back + title + actions doesn't fit at phone width.
///
/// Screen-specific [actions] go before the bell/avatar. Pass
/// `showNotifications: false` on the Notifications screen itself, and
/// `showAccount: false` where the bar is already crowded.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;

  /// Replaces [title]'s text when a screen needs a custom title (e.g. a
  /// chat group's avatar + name).
  final Widget? titleWidget;
  final String? subtitle;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final bool showNotifications;
  final bool showAccount;

  const BrandAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.showNotifications = true,
    this.showAccount = true,
  }) : assert(title != null || titleWidget != null);

  static const double _toolbarHeight = 72;

  @override
  Size get preferredSize => Size.fromHeight(_toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final hasBack = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final textTheme = Theme.of(context).textTheme;

    final titleContent =
        titleWidget ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ],
        );

    return AppBar(
      toolbarHeight: _toolbarHeight,
      titleSpacing: hasBack ? 0 : NavigationToolbar.kMiddleSpacing,
      title: Row(
        children: [
          if (!hasBack) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.asset('assets/icon/app_icon.png', width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: titleContent),
        ],
      ),
      actions: [
        ...actions,
        if (showNotifications) const _Bell(),
        if (showAccount) const _Account(),
        if (showNotifications || showAccount) const SizedBox(width: AppSpacing.xs),
      ],
      bottom: bottom,
    );
  }
}

/// Screens are also pumped standalone in widget tests without the
/// app-root providers — the bell/avatar just don't render there.
T? _maybeWatch<T>(BuildContext context) {
  try {
    return Provider.of<T>(context);
  } on ProviderNotFoundException {
    return null;
  }
}

class _Bell extends StatelessWidget {
  const _Bell();

  @override
  Widget build(BuildContext context) {
    final notifications = _maybeWatch<NotificationProvider>(context);
    if (notifications == null) return const SizedBox.shrink();
    return BrandNotificationBell(unreadCount: notifications.unreadCount);
  }
}

class _Account extends StatelessWidget {
  const _Account();

  @override
  Widget build(BuildContext context) {
    final auth = _maybeWatch<AuthProvider>(context);
    if (auth == null) return const SizedBox.shrink();
    return BrandAccountMenu(initials: initialsFor(auth.user?.fullName ?? ''));
  }
}
