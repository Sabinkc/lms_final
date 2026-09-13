import 'package:flutter/material.dart';

/// A horizontally-scrollable row of pill-style choice chips, optionally
/// showing a count badge per option (e.g. "All 12"). Generalizes the ad hoc
/// `ChoiceChip` rows already duplicated in `admin_fees_screen.dart`'s status
/// filter and `students_list_screen.dart`'s `_ClassFilterBar` — same
/// selection-callback shape, just one shared look.
class AppFilterChipBar<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T option) labelBuilder;
  final int Function(T option)? countBuilder;

  const AppFilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
    this.countBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final count = countBuilder?.call(option);
          return ChoiceChip(
            label: Text(count != null ? '${labelBuilder(option)} $count' : labelBuilder(option)),
            selected: option == selected,
            onSelected: (_) => onSelected(option),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
