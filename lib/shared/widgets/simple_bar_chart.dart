import 'package:flutter/material.dart';

/// A minimal proportional bar chart — one column per value, height scaled
/// against the largest value in the set. Same zero-dependency spirit as
/// `reports_screen.dart`'s private `_BreakdownBar` (a horizontal version of
/// the same idea), generalized into a shared vertical-bars widget since no
/// charting package is installed in this app.
class SimpleBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color? barColor;
  final double height;

  // Not `const`: the CFE can't fold `values.length` in a const constructor's
  // assert when `values` is a constructor parameter rather than a literal.
  // ignore: prefer_const_constructors_in_immutables
  SimpleBarChart({super.key, required this.values, required this.labels, this.barColor, this.height = 120})
    : assert(values.length == labels.length);

  @override
  Widget build(BuildContext context) {
    final color = barColor ?? Theme.of(context).colorScheme.primary;
    final maxValue = values.fold<double>(0, (a, b) => b > a ? b : a);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: maxValue > 0 ? (values[i] / maxValue).clamp(0.03, 1.0) : 0.03,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.85),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: Theme.of(context).textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
