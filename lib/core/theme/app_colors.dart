import 'package:flutter/material.dart';

/// Real values extracted from the live site's compiled CSS (docs/design_
/// system.md §1) — high confidence. The exact color-**role** mapping
/// (e.g. confirming `#00BB7F` really is the primary brand color and not
/// just a "success" status color) is flagged `ASSUMPTION — verify visually`
/// there; values themselves are not guessed.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF00BB7F);
  static const Color secondary = Color(0xFF625FFF);
  static const Color secondaryAlt = Color(0xFF8D54FF);
  static const Color secondaryAlt2 = Color(0xFF4F39F6);
  static const Color info = Color(0xFF3080FF);
  static const Color danger = Color(0xFFFF2357);
  static const Color warning = Color(0xFFF99C00);

  // Dark-mode surface ladder, darkest → lightest (design_system.md §1).
  static const Color darkBase = Color(0xFF0F172A);
  static const Color darkElevated1 = Color(0xFF111623);
  static const Color darkElevated2 = Color(0xFF181F30);
  static const Color darkElevated3 = Color(0xFF1A2536);
  static const Color darkElevated4 = Color(0xFF243044);

  // Light-mode surfaces.
  static const Color lightBase = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFF8FAFC);
}
