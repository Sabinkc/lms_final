import 'package:flutter/material.dart';

import '../../../../shared/utils/format_rs.dart';

/// Paid-vs-total bar for one fee, with "Rs. 4,000 of Rs. 10,000 paid".
class FeeProgressBar extends StatelessWidget {
  final double paid;
  final double total;
  final Color color;

  const FeeProgressBar({super.key, required this.paid, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    return Semantics(
      label: '${formatRs(paid)} of ${formatRs(total)} paid',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: Text(
              '${formatRs(paid)} of ${formatRs(total)} paid',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
