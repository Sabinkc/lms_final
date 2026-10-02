import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

/// Gently pulses its child between 55% and 100% opacity — the "still
/// loading" heartbeat for skeleton shapes. Holds still when the system asks
/// for reduced motion.
class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = 0.5 - 0.5 * math.cos(_controller.value * 2 * math.pi);
        return Opacity(opacity: 0.55 + 0.45 * t, child: child);
      },
      child: widget.child,
    );
  }
}

/// A grey placeholder block.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? radius;

  const SkeletonBox({super.key, this.width, required this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07),
        borderRadius: radius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Card-shaped skeleton rows (badge, title, subtitle) standing in for a list
/// that's loading. Fills the available height when it has one; inside an
/// unbounded parent (e.g. a section of a scrolling page) it shows a few rows.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const rowHeight = 90.0;
        final count = constraints.hasBoundedHeight
            ? math.max(1, ((constraints.maxHeight - 16) / rowHeight).floor())
            : 3;
        return ClipRect(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _SkeletonCard(titleWidth: 120.0 + (i * 37 % 60)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double titleWidth;

  const _SkeletonCard({required this.titleWidth});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SkeletonPulse(
          child: Row(
            children: [
              SkeletonBox(width: 52, height: 52, radius: BorderRadius.circular(AppRadius.xl2)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: titleWidth, height: 14),
                    const SizedBox(height: 8),
                    const SkeletonBox(width: 80, height: 11),
                  ],
                ),
              ),
              const SkeletonBox(width: 22, height: 22, radius: BorderRadius.all(Radius.circular(11))),
            ],
          ),
        ),
      ),
    );
  }
}
