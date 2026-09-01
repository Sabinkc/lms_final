import 'package:flutter/material.dart';

import '../../features/auth/data/models/app_role.dart';

/// Resolves docs/design_system.md §1's `CONFLICT`: v0.2 guessed these
/// values from the *live* site's compiled CSS (`#00BB7F` primary); v0.3
/// read the real web frontend's source directly and found none of v0.2's
/// hex values anywhere in it. These are v0.3's confirmed values instead —
/// emerald primary (the most-used non-neutral color app-wide, `bg-emerald-
/// 500/600` — grep-counted), indigo secondary/info, amber warning, rose
/// danger (all confirmed Tailwind color *families*, not guessed), plus a
/// per-role accent taken verbatim from the real `roles.tsx`.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF059669); // emerald-600
  static const Color secondary = Color(0xFF4F46E5); // indigo-600
  static const Color info = Color(0xFF4F46E5); // indigo-600 — same family as secondary
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color danger = Color(0xFFF43F5E); // rose-500

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
