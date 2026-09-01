/// `CONFIRMED` (docs/design_system.md §3): grep-counted Tailwind spacing
/// utility usage across the real web frontend's source confirms this exact
/// scale (4px base), with 2/3/4 (8/12/16px) as the dominant working set for
/// gaps/padding and 4–6 (16–24px) for card/section padding — revises the
/// earlier `ASSUMPTION`-flagged 4/8/12/16/24/32/48 guess, which skipped 20
/// and jumped straight to values not heavily used in the real app.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xl2 = 24;
}
