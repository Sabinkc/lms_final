import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/readable_color.dart';

/// Briefly celebrates a finished action (attendance submitted, payment sent,
/// results published): a tick that pops in and draws itself, a short title
/// and subtitle, and a light vibration. Closes itself after ~1.6 s or on tap.
Future<void> showSuccess(BuildContext context, {required String title, String? subtitle}) {
  HapticFeedback.mediumImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (dialogContext, _, _) => _SuccessCard(title: title, subtitle: subtitle),
  );
}

class _SuccessCard extends StatefulWidget {
  final String title;
  final String? subtitle;

  const _SuccessCard({required this.title, this.subtitle});

  @override
  State<_SuccessCard> createState() => _SuccessCardState();
}

class _SuccessCardState extends State<_SuccessCard> with SingleTickerProviderStateMixin {
  // The whole life of the card is one animation: pop + draw in the first
  // ~0.9 s, then it holds and closes when the controller completes (no
  // separate timer).
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) Navigator.of(context).maybePop();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final theme = Theme.of(context);
    final color = context.readable(AppColors.success);
    return Center(
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = reduceMotion ? 1.0 : _controller.value / 0.5625; // 0.9 s of the 1.6 s
              final pop = Curves.elasticOut.transform((t / 0.55).clamp(0.0, 1.0));
              final draw = Curves.easeOut.transform(((t - 0.35) / 0.45).clamp(0.0, 1.0));
              final text = ((t - 0.5) / 0.4).clamp(0.0, 1.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: pop,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: CustomPaint(painter: _TickPainter(draw, color)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: text,
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(widget.subtitle!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  final double progress;
  final Color color;

  _TickPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.67)
      ..lineTo(size.width * 0.73, size.height * 0.36);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
