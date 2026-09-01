/// `ASSUMPTION` (docs/design_system.md §3): not recoverable from the CSS
/// scan, so this is a standard 4px-base/8pt-grid convention — both a
/// Flutter/Material default and a typical Tailwind scale — pending visual
/// confirmation, not an invented one-off value.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xl2 = 32;
  static const double xl3 = 48;
}
