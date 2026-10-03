import 'dart:math';

import 'package:flutter/material.dart';

/// Opens a form as a bottom sheet instead of a centred dialog — fields get
/// the full width and the buttons sit within thumb reach. Uses the root
/// navigator like `showDialog` does, so the sheet covers the bottom nav bar.
Future<T?> showFormSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: builder,
  );
}

/// The sheet's body. Takes the same [title]/[content]/[actions] as an
/// `AlertDialog`, so a dialog form converts by swapping the two names.
/// [actions] become full-width buttons in a row (Cancel first, the primary
/// action last); the content scrolls and stays above the keyboard.
class FormSheet extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget> actions;

  const FormSheet({super.key, required this.title, required this.content, required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.primary.withValues(alpha: 0.5);
    // Clear the keyboard when it's open, otherwise the gesture/nav bar.
    final bottomInset = max(MediaQuery.viewInsetsOf(context).bottom, MediaQuery.paddingOf(context).bottom);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DefaultTextStyle(
            style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700),
            child: title,
          ),
          const SizedBox(height: 16),
          Flexible(child: SingleChildScrollView(child: content)),
          const SizedBox(height: 20),
          // Text buttons (Cancel) get an outline so both halves read as buttons.
          TextButtonTheme(
            data: TextButtonThemeData(
              style:
                  theme.textButtonTheme.style?.merge(TextButton.styleFrom(side: BorderSide(color: outline))) ??
                  TextButton.styleFrom(side: BorderSide(color: outline)),
            ),
            child: Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: SizedBox(height: 50, child: actions[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
