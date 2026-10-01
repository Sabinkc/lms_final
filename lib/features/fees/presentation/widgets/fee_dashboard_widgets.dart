import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

import '../../../../shared/utils/format_rs.dart';

export '../../../../shared/utils/format_rs.dart';

/// Fee-status palette shared by the Admin Fees dashboard's stat cards,
/// chart legend, donut and status chips so one status is one color
/// everywhere on the screen.
abstract final class FeeColors {
  static const Color paid = AppColors.primary;
  static const Color partial = Color(0xFFF59E0B);
  static const Color pending = Color(0xFFE4572E);

  /// The lighter second series in the collected-vs-pending bar chart.
  static const Color pendingBar = Color(0xFF8FD3B4);
}


/// Compact axis label: `85K`, `2.5L`, `1.2Cr`.
String _compactRs(double v) {
  String trim(double x) => x == x.roundToDouble() ? x.toStringAsFixed(0) : x.toStringAsFixed(1);
  if (v >= 10000000) return '${trim(v / 10000000)}Cr';
  if (v >= 100000) return '${trim(v / 100000)}L';
  if (v >= 1000) return '${trim(v / 1000)}K';
  return v.toStringAsFixed(0);
}

/// Tinted stat card from the reference: icon in a soft circle, label, a
/// large value in the card's accent color, and a muted caption below.
class FeeStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color color;

  /// Colors the value/label with [color] (Collected/Pending) instead of the
  /// default on-surface text (Total/Today).
  final bool emphasize;

  const FeeStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = emphasize ? color : theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: textColor),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: textColor),
                ),
              ),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Legend dot + label, used under/above both charts.
class FeeLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const FeeLegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Stacked collected (dark) + pending (light) bars per month, with a
/// 5-step y-axis in compact rupee units — the reference's "Fee Collection
/// Overview". Plain widgets rather than a chart package.
class FeeStackedBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> collected;
  final List<double> pending;
  final double height;

  const FeeStackedBarChart({
    super.key,
    required this.labels,
    required this.collected,
    required this.pending,
    this.height = 170,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final axisStyle = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final maxTotal = [for (var i = 0; i < labels.length; i++) collected[i] + pending[i]].fold<double>(0, math.max);
    final axisMax = _niceCeil(maxTotal);
    const steps = 5;
    final gridColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Y-axis labels, top (max) to bottom (0).
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [for (var s = steps; s >= 0; s--) Text(_compactRs(axisMax * s / steps), style: axisStyle)],
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final plotH = constraints.maxHeight;
                    final slot = constraints.maxWidth / labels.length;
                    final barW = math.min(22.0, slot * 0.55);
                    return Stack(
                      children: [
                        for (var s = 0; s <= steps; s++)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: (plotH - 1) * s / steps,
                            child: Container(height: 1, color: gridColor),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < labels.length; i++)
                              SizedBox(
                                width: slot,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: barW,
                                      height: axisMax > 0 ? plotH * pending[i] / axisMax : 0,
                                      decoration: BoxDecoration(
                                        color: FeeColors.pendingBar,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sm)),
                                      ),
                                    ),
                                    Container(
                                      width: barW,
                                      height: axisMax > 0 ? plotH * collected[i] / axisMax : 0,
                                      decoration: BoxDecoration(
                                        color: FeeColors.paid,
                                        borderRadius: pending[i] > 0
                                            ? null
                                            : const BorderRadius.vertical(top: Radius.circular(AppRadius.sm)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            // Aligns month labels under the plot, past the y-axis column.
            Opacity(opacity: 0, child: Text(_compactRs(axisMax), style: axisStyle)),
            const SizedBox(width: AppSpacing.sm),
            for (final label in labels)
              Expanded(
                child: Text(label, textAlign: TextAlign.center, style: axisStyle),
              ),
          ],
        ),
      ],
    );
  }

  /// Rounds [v] up to a 1/2/2.5/5 × 10ⁿ step so the axis reads cleanly.
  static double _niceCeil(double v) {
    if (v <= 0) return 1;
    final magnitude = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (m * magnitude >= v) return m * magnitude;
    }
    return 10 * magnitude;
  }
}

/// One slice of [FeeStatusDonut].
typedef FeeDonutSlice = ({String label, double amount, Color color});

/// The reference's "Fee Status" ring: slices by fee status with the total in
/// the middle, and an amount + share legend below.
class FeeStatusDonut extends StatelessWidget {
  final List<FeeDonutSlice> slices;
  final double total;

  const FeeStatusDonut({super.key, required this.slices, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sum = slices.fold<double>(0, (s, e) => s + e.amount);
    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: CustomPaint(
            painter: _DonutPainter(
              slices: slices,
              sum: sum,
              trackColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: theme.textTheme.bodySmall),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatRs(total),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final slice in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(slice.label, style: theme.textTheme.bodyMedium)),
                Text(formatRs(slice.amount), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(
                  width: 64,
                  child: Text(
                    '(${sum > 0 ? (slice.amount / sum * 100).toStringAsFixed(1) : '0.0'}%)',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<FeeDonutSlice> slices;
  final double sum;
  final Color trackColor;

  _DonutPainter({required this.slices, required this.sum, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 20.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    if (sum <= 0) {
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = trackColor);
      return;
    }
    var start = -math.pi / 2;
    for (final slice in slices) {
      if (slice.amount <= 0) continue;
      final sweep = 2 * math.pi * slice.amount / sum;
      canvas.drawArc(rect, start, sweep, false, paint..color = slice.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.slices != slices || old.sum != sum || old.trackColor != trackColor;
}
