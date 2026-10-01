import 'package:flutter/material.dart';

/// Brand/status colours (e.g. `AppColors.primary` #0B6E4F) are tuned for the
/// light theme; used as text or icons on the dark theme's near-black
/// surfaces they become hard to read. [readable] returns [color] unchanged
/// in light mode and, in dark mode, blends it toward white just enough to
/// reach WCAG AA contrast (4.5:1) against the dark background.
extension ReadableColor on BuildContext {
  Color readable(Color color) => readableColor(color, Theme.of(this).brightness);
}

/// Pure version of [ReadableColor.readable], for code without a context.
Color readableColor(Color color, Brightness brightness) {
  if (brightness == Brightness.light) return color;
  // Dark surfaces in this app sit around luminance 0.01–0.02; 0.25 keeps
  // ≥ 4.5:1 against them.
  const target = 0.25;
  var c = color;
  for (var t = 0.1; c.computeLuminance() < target && t <= 1.0; t += 0.1) {
    c = Color.lerp(color, Colors.white, t)!;
  }
  return c;
}
