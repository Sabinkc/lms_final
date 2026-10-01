import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/readable_color.dart';

/// A tinted inset row inside a card — leading icon + text, with an optional
/// emphasized value on the right (e.g. "📅 12 Sep 2026 · · · 100 Total
/// Marks"). The recurring "detail strip" from the Stitch mockups.
class InfoStrip extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? trailing;
  final Color color;

  const InfoStrip({super.key, required this.icon, required this.text, this.trailing, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = context.readable(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: fg),
            ),
          ],
        ],
      ),
    );
  }
}
