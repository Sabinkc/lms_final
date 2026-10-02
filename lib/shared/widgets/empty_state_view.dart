import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/readable_color.dart';

/// Generic empty state — a small hand-drawn-style illustration (a sheet of
/// paper on a soft circle, with a leaf sprig and the screen's own [icon] as a
/// badge), the message, and an optional primary action. Drawn in code with
/// the palette colours, so it matches light and dark mode and costs no asset.
class EmptyStateView extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({super.key, required this.message, this.icon, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        // In a short space (a panel, not a whole screen) fall back to just the
        // icon so nothing overflows.
        final compact = constraints.hasBoundedHeight && constraints.maxHeight < 260;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (compact && icon != null) ...[
                  Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                ] else if (!compact)
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 150,
                      height: 124,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _EmptyIllustrationPainter(isDark: isDark)),
                          ),
                          if (icon != null)
                            Positioned(
                              right: 18,
                              top: 10,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkElevated3 : AppColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.clay.withValues(alpha: 0.5), width: 1.5),
                                ),
                                child: Icon(icon, size: 20, color: context.readable(AppColors.clay)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (!compact) const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Line drawing: soft backdrop circle, a slightly tilted sheet with ruled
/// lines (one "written" line a little wavy, like handwriting), and a sprig.
class _EmptyIllustrationPainter extends CustomPainter {
  final bool isDark;

  _EmptyIllustrationPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final ink = isDark ? AppColors.primaryLight : AppColors.primary;
    final centre = Offset(size.width / 2, size.height / 2 + 4);

    canvas.drawCircle(
      centre,
      size.height * 0.46,
      Paint()..color = (isDark ? AppColors.primary : AppColors.primarySoft).withValues(alpha: isDark ? 0.22 : 1),
    );

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(-6 * math.pi / 180);
    final sheet = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 70, height: 84),
      const Radius.circular(8),
    );
    canvas.drawRRect(sheet, Paint()..color = isDark ? AppColors.darkElevated2 : AppColors.surface);
    final stroke = Paint()
      ..color = ink.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(sheet, stroke);
    final lines = Paint()
      ..color = ink.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    // A wavy "handwritten" first line, then plain ruled lines.
    final hand = Path()..moveTo(-24, -24);
    for (var x = -24.0; x <= 14; x += 2) {
      hand.lineTo(x, -24 + math.sin(x / 3) * 1.6);
    }
    canvas.drawPath(hand, stroke..color = ink.withValues(alpha: 0.6));
    for (final (y, w) in const [(-10.0, 44.0), (4.0, 38.0), (18.0, 28.0)]) {
      canvas.drawLine(Offset(-24, y), Offset(-24 + w, y), lines);
    }
    canvas.restore();

    // Leaf sprig rising from the bottom-left.
    final sprig = Paint()
      ..color = AppColors.clay.withValues(alpha: isDark ? 0.9 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final base = Offset(size.width * 0.2, size.height * 0.9);
    final stem = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + 4, base.dy - 26, base.dx + 14, base.dy - 44);
    canvas.drawPath(stem, sprig);
    void leaf(Offset at, double angle) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle);
      final shape = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(7, -6, 14, 0)
        ..quadraticBezierTo(7, 6, 0, 0);
      canvas.drawPath(shape, Paint()..color = AppColors.clay.withValues(alpha: isDark ? 0.5 : 0.35));
      canvas.drawPath(shape, sprig);
      canvas.restore();
    }

    leaf(Offset(base.dx + 3, base.dy - 14), -0.5);
    leaf(Offset(base.dx + 6, base.dy - 28), -2.4);
    leaf(Offset(base.dx + 12, base.dy - 40), -0.9);
  }

  @override
  bool shouldRepaint(_EmptyIllustrationPainter oldDelegate) => oldDelegate.isDark != isDark;
}
