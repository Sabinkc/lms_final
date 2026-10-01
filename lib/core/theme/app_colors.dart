import 'package:flutter/material.dart';

import '../../features/auth/data/models/app_role.dart';

/// Switched 2026-09-14 to the "Verdant Scholar" palette used throughout
/// the Google Stitch mockups (`docs/stitch_screens/`) — checked directly
/// against every role's own Home Dashboard export (Admin/Teacher/Student/
/// Parent all embed the *identical* `primary`/`primary-container` hex
/// values in their tailwind config, confirming Stitch's design is a single
/// uniform forest-green brand identity, not a per-role-tinted one like the
/// app previously had). `primaryContainer` (`#0b6e4f`) is the shade that
/// actually reads as "the app's color" on screen — hero banners, filled
/// buttons, active nav — since Material 3's `ColorScheme.fromSeed` derives
/// every other tone from one seed, that's the seed used here rather than
/// the darker `primary` (`#00543b`, used by Stitch mostly as a gradient
/// end-stop). Superseded the prior emerald-600 (`#059669`) v0.3 value,
/// which was correct for the *real production web app* but visibly
/// different from what the Stitch designs actually specify — this file
/// now tracks the Stitch design system instead, per explicit user request
/// to match those mockups exactly. Secondary/warning/danger kept from the
/// nearest matching real Stitch tokens (`secondary`/`tertiary`/`error`).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0B6E4F); // Stitch primary-container
  static const Color primaryDark = Color(0xFF00543B); // Stitch primary (gradient end-stop)
  static const Color secondary = Color(0xFF006C49); // Stitch secondary
  static const Color info = Color(0xFF4F46E5); // indigo-600 — unchanged, no Stitch equivalent token
  static const Color warning = Color(0xFF885500); // Stitch tertiary-container
  static const Color danger = Color(0xFFBA1A1A); // Stitch error

  // Dark-mode surface ladder, darkest → lightest (design_system.md §1).
  static const Color darkBase = Color(0xFF0F172A);
  static const Color darkElevated1 = Color(0xFF111623);
  static const Color darkElevated2 = Color(0xFF181F30);
  static const Color darkElevated3 = Color(0xFF1A2536);
  static const Color darkElevated4 = Color(0xFF243044);

  // Light-mode surfaces.
  static const Color lightBase = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFF8FAFC);

  /// Per-role brand color — `CONFIRMED`, real and precise: `roles.tsx`
  /// assigns exactly these hex values per role for badges/icons/chrome.
  /// (SuperAdmin's `#DC2626` is omitted — out of this app's 4-role scope.)
  static Color roleColor(AppRole role) => switch (role) {
        AppRole.student => const Color(0xFF4F46E5), // indigo-600
        AppRole.teacher => const Color(0xFF0891B2), // cyan-600
        AppRole.parent => const Color(0xFF059669), // emerald-600
        AppRole.admin => const Color(0xFFD97706), // amber-600
      };
}
