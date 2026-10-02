import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Soft, modern app background to replace plain white screens: a faint
/// mint-to-white wash, a few large blurred colour glows (brand green, blue,
/// teal), two gentle wave bands, and a light dot grid at the top. Kept very
/// low-contrast so cards and text stay the focus.
///
/// Every role's screens wrap their `Scaffold` in this (with a transparent
/// `backgroundColor`) since 2026-10-01 — one per page rather than one
/// behind the whole app, so page transitions don't show two screens
/// through each other. App bars are transparent app-wide (`AppTheme`).
class AppBackground extends StatelessWidget {
  final Widget? child;

  const AppBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    // Own repaint layer: scrolling the page on top doesn't repaint the
    // blurred shapes underneath.
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: AppBackgroundPainter(brightness: Theme.of(context).brightness)),
        ),
        ?child,
      ],
    );
  }
}

class AppBackgroundPainter extends CustomPainter {
  final Brightness brightness;

  const AppBackgroundPainter({this.brightness = Brightness.light});

  bool get _dark => brightness == Brightness.dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // 1. Base wash.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(w * 0.4, h),
          _dark
              ? const [AppColors.darkBase, AppColors.darkElevated1, AppColors.darkBase]
              : const [AppColors.paper, Color(0xFFFFFFFF), AppColors.paper],
          const [0.0, 0.55, 1.0],
        ),
    );

    // 2. Blurred colour glows.
    void glow(Offset c, double r, Color color, double opacity) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.55),
      );
    }

    final k = _dark ? 1.6 : 1.0;
    glow(Offset(w * 1.02, h * 0.02), w * 0.55, AppColors.primary, 0.13 * k);
    glow(Offset(-w * 0.12, h * 0.40), w * 0.48, AppColors.slate, 0.08 * k);
    glow(Offset(w * 0.95, h * 0.72), w * 0.42, AppColors.teal, 0.09 * k);
    glow(Offset(w * 0.15, h * 1.02), w * 0.50, AppColors.primary, 0.08 * k);

    // 3. Wave bands — top-right and bottom.
    Path wave(double baseY, double amp, double phase, {bool fromTop = false}) {
      final p = Path();
      if (fromTop) {
        p.moveTo(0, 0);
        p.lineTo(0, baseY);
      } else {
        p.moveTo(0, h);
        p.lineTo(0, baseY);
      }
      for (double x = 0; x <= w; x += w / 60) {
        final y = baseY + math.sin((x / w) * 2 * math.pi + phase) * amp;
        p.lineTo(x, y);
      }
      p.lineTo(w, fromTop ? 0 : h);
      p.close();
      return p;
    }

    final waveColor = _dark ? AppColors.primaryLight : AppColors.primary;
    canvas.drawPath(
      wave(h * 0.13, h * 0.025, 0.6, fromTop: true),
      Paint()
        ..shader = ui.Gradient.linear(Offset(w, 0), Offset(0, h * 0.16), [
          waveColor.withValues(alpha: _dark ? 0.10 : 0.07),
          waveColor.withValues(alpha: 0.0),
        ]),
    );
    canvas.drawPath(
      wave(h * 0.86, h * 0.022, 2.2),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, h), Offset(w, h * 0.82), [
          waveColor.withValues(alpha: _dark ? 0.12 : 0.08),
          waveColor.withValues(alpha: 0.01),
        ]),
    );
    canvas.drawPath(
      wave(h * 0.91, h * 0.018, 3.6),
      Paint()
        ..shader = ui.Gradient.linear(Offset(w, h), Offset(0, h * 0.88), [
          AppColors.slate.withValues(alpha: _dark ? 0.10 : 0.06),
          const Color(0x002F80FF),
        ]),
    );

    // 4. Thin line accents: a flowing curve + two rings, top-right.
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = waveColor.withValues(alpha: _dark ? 0.14 : 0.10);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.35, 0)
        ..cubicTo(w * 0.55, h * 0.10, w * 0.75, h * 0.02, w, h * 0.16),
      line,
    );
    canvas.drawCircle(Offset(w * 0.9, h * 0.08), w * 0.14, line);
    canvas.drawCircle(
      Offset(w * 0.9, h * 0.08),
      w * 0.22,
      line..color = line.color.withValues(alpha: _dark ? 0.08 : 0.06),
    );

    // 5. Dot grid, top-left, fading out.
    const spacing = 18.0;
    for (double y = spacing; y < h * 0.22; y += spacing) {
      for (double x = spacing; x < w * 0.45; x += spacing) {
        final fade = (1 - x / (w * 0.45)) * (1 - y / (h * 0.22));
        if (fade <= 0.05) continue;
        canvas.drawCircle(
          Offset(x, y),
          1.2,
          Paint()..color = (_dark ? Colors.white : AppColors.primary).withValues(alpha: 0.10 * fade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(AppBackgroundPainter oldDelegate) => oldDelegate.brightness != brightness;
}
