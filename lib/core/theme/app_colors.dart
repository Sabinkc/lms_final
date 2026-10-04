import 'package:flutter/material.dart';

import '../../features/auth/data/models/app_role.dart';

/// The app's colour system — palette "Deep Teal": deep teal leads,
/// emerald green carries success/positive states, orange is the accent,
/// on clean white neutrals.
///
/// Roughly 60% neutral white, 30% teal, 10% orange/emerald. Every colour in
/// the app comes from here — never hard-code a hex in a screen. Brand
/// colours are tuned for the light theme; wrap them in `context.readable`
/// when used as text or icons so they stay legible in dark mode.
class AppColors {
  AppColors._();

  // Brand.
  static const Color primary = Color(0xFF0E5E6F);
  static const Color primaryDark = Color(0xFF09434F);
  static const Color primaryLight = Color(0xFF4FA3B0);
  static const Color primarySoft = Color(0xFFE1F0F2);
  static const Color accent = Color(0xFFF07B22);
  static const Color accentSoft = Color(0xFFFEEADB);

  // Status.
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFE08A1E);
  static const Color danger = Color(0xFFD14343);
  static const Color info = Color(0xFF2E6F9E);

  // Category tones — class badges, quick-action icons, chart series.
  static const Color teal = Color(0xFF059669);
  static const Color slate = Color(0xFF3F6E95);
  static const Color plum = Color(0xFF7A5579);
  static const Color clay = Color(0xFFF07B22);
  static const Color ochre = Color(0xFFE5A21B);
  static const Color rose = Color(0xFFB24E6A);
  static const Color moss = Color(0xFF10B981);

  // Deeper shades of the tones, for gradient end-stops.
  static const Color slateDeep = Color(0xFF2F5373);
  static const Color clayDeep = Color(0xFFC25E12);
  static const Color mossDeep = Color(0xFF047857);
  static const Color plumDeep = Color(0xFF5F425E);
  static const Color ochreDeep = Color(0xFFB57D10);
  static const Color tealDeep = Color(0xFF047857);
  static const Color roseDeep = Color(0xFF8A3C52);

  /// The tones in a fixed order, for cycling (e.g. by a hash of a name).
  static const List<Color> tones = [primary, clay, slate, ochre, teal, plum, rose, moss];

  // Neutrals (light).
  static const Color ink = Color(0xFF0F2A30);
  static const Color inkMuted = Color(0xFF5A6E73);
  static const Color line = Color(0xFFDDE8EA);
  static const Color paper = Color(0xFFF6FAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color lightBase = paper;
  static const Color lightElevated = surface;
  static const Color secondary = primaryDark;

  // Dark-mode surface ladder, darkest → lightest (teal-tinted, not slate).
  static const Color darkBase = Color(0xFF0B1518);
  static const Color darkElevated1 = Color(0xFF0F1C20);
  static const Color darkElevated2 = Color(0xFF142428);
  static const Color darkElevated3 = Color(0xFF1A2C31);
  static const Color darkElevated4 = Color(0xFF22383E);

  /// Per-role colour for role badges/chips.
  static Color roleColor(AppRole role) => switch (role) {
    AppRole.student => slate,
    AppRole.teacher => teal,
    AppRole.parent => plum,
    AppRole.admin => clay,
  };
}
