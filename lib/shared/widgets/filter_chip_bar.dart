import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// A horizontally-scrollable row of pill-style choice chips, optionally
/// showing an icon and a count badge per option (e.g. "All [12]"). One shared
/// look for every list filter — the Notices category chips this was
/// promoted from, Fees status, Students class, child pickers, etc.
class AppFilterChipBar<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T option) labelBuilder;
  final int Function(T option)? countBuilder;
  final IconData? Function(T option)? iconBuilder;

  const AppFilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
    this.countBuilder,
    this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          return Center(
            child: AppFilterChip(
              label: labelBuilder(option),
              icon: iconBuilder?.call(option),
              count: countBuilder?.call(option),
              selected: option == selected,
              onTap: () => onSelected(option),
            ),
          );
        },
      ),
    );
  }
}

/// A single filter pill: filled brand green when selected, outlined
/// otherwise, with an optional leading icon and trailing count badge.
class AppFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    this.icon,
    this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? Colors.white : theme.colorScheme.onSurface;
    return Material(
      color: selected ? AppColors.primary : theme.colorScheme.surfaceContainerLow,
      shape: StadiumBorder(side: selected ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? Colors.white : AppColors.primary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xl4),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
