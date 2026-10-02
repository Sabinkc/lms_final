import 'package:flutter/material.dart';

import '../../features/auth/data/models/app_role.dart';

/// The app's colour system — palette "Forest & Clay". Split-complementary warm scheme: forest green with a terracotta accent and ochre, on warm paper neutrals.
///
/// Built around the brand green with colour theory rather than stock web
/// colours: roughly 60% neutral paper, 30% green, 10% accent; status and
/// category colours share the green's muted saturation so nothing shouts.
/// Every colour in the app comes from here — never hard-code a hex in a
/// screen.
class AppColors {
  AppColors._();

  // Brand.
  static const Color primary = Color(0xFF0B6E4F);
  static const Color primaryDark = Color(0xFF08523B);
  static const Color primaryLight = Color(0xFF5FAE8C);
  static const Color primarySoft = Color(0xFFE2EFE8);
  static const Color accent = Color(0xFFC2603E);
  static const Color accentSoft = Color(0xFFF5E3DA);

  // Status.
  static const Color success = Color(0xFF2E8A5A);
  static const Color warning = Color(0xFFC7821B);
  static const Color danger = Color(0xFFB4412F);
  static const Color info = Color(0xFF3D6A8C);

  // Category tones — class badges, quick-action icons, chart series.
  static const Color teal = Color(0xFF2B7A78);
  static const Color slate = Color(0xFF4D6788);
  static const Color plum = Color(0xFF7A5579);
  static const Color clay = Color(0xFFC2603E);
  static const Color ochre = Color(0xFFC9922A);
  static const Color rose = Color(0xFFB24E6A);
  static const Color moss = Color(0xFF6A8A3A);

  // Deeper shades of the tones, for gradient end-stops.
  static const Color slateDeep = Color(0xFF3C506A);
  static const Color clayDeep = Color(0xFF974A30);
  static const Color mossDeep = Color(0xFF526B2D);
  static const Color plumDeep = Color(0xFF5F425E);
  static const Color ochreDeep = Color(0xFF9C7120);
  static const Color tealDeep = Color(0xFF215F5D);
  static const Color roseDeep = Color(0xFF8A3C52);

  /// The tones in a fixed order, for cycling (e.g. by a hash of a name).
  static const List<Color> tones = [primary, clay, slate, ochre, teal, plum, rose, moss];

  // Neutrals (light).
  static const Color ink = Color(0xFF1D2A25);
  static const Color inkMuted = Color(0xFF5F6B66);
  static const Color line = Color(0xFFE2DFD5);
  static const Color paper = Color(0xFFF8F6F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color lightBase = paper;
  static const Color lightElevated = surface;
  static const Color secondary = primaryDark;

  // Dark-mode surface ladder, darkest → lightest (green-tinted, not slate).
  static const Color darkBase = Color(0xFF0F1613);
  static const Color darkElevated1 = Color(0xFF141C18);
  static const Color darkElevated2 = Color(0xFF19231F);
  static const Color darkElevated3 = Color(0xFF1F2B26);
  static const Color darkElevated4 = Color(0xFF283530);

  /// Per-role colour for role badges/chips.
  static Color roleColor(AppRole role) => switch (role) {
    AppRole.student => slate,
    AppRole.teacher => teal,
    AppRole.parent => plum,
    AppRole.admin => clay,
  };
}
