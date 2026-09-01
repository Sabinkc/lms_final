import 'package:flutter/material.dart';

/// `ASSUMPTION` (docs/design_system.md §2): the live site loads no custom
/// webfont, just the OS system-font stack, which isn't portable to Flutter
/// the same way — Material 3's default `TextTheme` is used as the starting
/// scale rather than inventing sizes/weights that were never recoverable
/// from the CSS scan. Swap [fontFamily] here for a bundled font (e.g.
/// Inter) in one place if/when that design decision is made.
class AppTypography {
  AppTypography._();

  static const String? fontFamily = null; // null = platform default for now.

  static TextTheme textTheme(TextTheme base) => base.apply(fontFamily: fontFamily);
}
