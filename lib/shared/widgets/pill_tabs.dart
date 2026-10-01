import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// Pill-style tab row from the reference designs (Class Details, Student
/// Profile): the selected tab filled green on a soft rounded track. Tabs are
/// sized in proportion to their labels; labels scale down rather than
/// wrapping on narrow phones.
class PillTabs<T> extends StatelessWidget {
  final List<T> values;
  final String Function(T) labelOf;
  final IconData Function(T)? iconOf;
  final T selected;
  final ValueChanged<T> onSelected;

  const PillTabs({
    super.key,
    required this.values,
    required this.labelOf,
    this.iconOf,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.xl4),
      ),
      child: Row(
        children: [
          for (final value in values)
            // Width follows label length so every label renders at the same
            // size; equal-width tabs shrank only the long ones ("Attendance").
            Expanded(
              flex: labelOf(value).length + (iconOf != null ? 3 : 0),
              child: Material(
                color: value == selected ? AppColors.primary : Colors.transparent,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onSelected(value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (iconOf != null) ...[
                            Icon(
                              iconOf!(value),
                              size: 16,
                              color: value == selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            labelOf(value),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: value == selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
