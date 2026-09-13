import 'package:flutter/material.dart';

/// Real values extracted from the live site's compiled CSS (docs/design_
/// system.md §4) — high confidence, not a guess.
class AppRadius {
  AppRadius._();

  static const double xs = 2;
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
  static const double xl2 = 16;
  static const double xl3 = 24;
  static const double xl4 = 32;

  // Recommended component mapping (design_system.md §4/§5).
  // Card radius bumped from xl (12px) to xl2 (16px) for the 2026-09 UI
  // restyle pass — matches the rounder card shape in the reference designs;
  // cascades automatically via `app_theme.dart`'s `cardTheme`.
  static final BorderRadius card = BorderRadius.circular(xl2);
  static final BorderRadius button = BorderRadius.circular(lg);
  static final BorderRadius textField = BorderRadius.circular(md);
  static final BorderRadius sheet = BorderRadius.circular(xl2);
}
