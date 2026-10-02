import 'package:flutter/material.dart';

import '../utils/format_rs.dart';

/// Shows [value] counting up from 0 the first time it appears. Only plain
/// counts, percentages and rupee amounts animate ("412", "92%",
/// "Rs. 23,000"); anything else ("—", "10:00 AM", a date) is shown as-is.
/// Later changes animate from the old number to the new one. Skips the
/// animation when the system asks for reduced motion.
class CountUpText extends StatelessWidget {
  final String value;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const CountUpText(this.value, {super.key, this.style, this.maxLines = 1, this.overflow = TextOverflow.ellipsis});

  static final _number = RegExp(r'^(Rs\. )?(\d[\d,]*)(%?)$');

  @override
  Widget build(BuildContext context) {
    final match = _number.firstMatch(value.trim());
    final target = match == null ? null : int.tryParse(match.group(2)!.replaceAll(',', ''));
    if (match == null || target == null || MediaQuery.disableAnimationsOf(context)) {
      return Text(value, style: style, maxLines: maxLines, overflow: overflow);
    }
    final prefix = match.group(1) ?? '';
    final suffix = match.group(3)!;
    final grouped = prefix.isNotEmpty || match.group(2)!.contains(',');
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) {
        final n = current.round();
        return Text(
          '$prefix${grouped ? _group(n) : '$n'}$suffix',
          style: style,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }

  /// 2480000 -> "24,80,000": the same South-Asian grouping as `formatRs`,
  /// so an amount keeps its shape while it counts.
  static String _group(int n) => formatRs(n.toDouble()).substring('Rs. '.length);
}
