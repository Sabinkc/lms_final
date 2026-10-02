import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pull-down-to-reload for a screen body, whatever that body currently is.
///
/// The body is placed in an always-scrollable outer view sized to exactly the
/// available space, so a pull works even when the body doesn't scroll itself
/// (loading, error and empty states, short pages). When the body has its own
/// list, that list is one level down and pulling it past the top refreshes
/// too ([notificationPredicate] accepts depth 0 and 1).
///
/// [onRefresh] should reload with `silent: true` so the current data stays
/// on screen until the new data arrives.
class PullToRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const PullToRefresh({super.key, required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        HapticFeedback.lightImpact();
        return onRefresh();
      },
      notificationPredicate: (notification) => notification.depth <= 1,
      child: CustomScrollView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [SliverFillRemaining(child: child)],
      ),
    );
  }
}
