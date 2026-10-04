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
  // Raise lightness rather than mixing in white, so the hue stays vivid
  // (teal stays teal instead of turning grey-blue).
  final hsl = HSLColor.fromColor(color);
  var c = color;
  for (var l = hsl.lightness; c.computeLuminance() < target && l < 1.0; l += 0.04) {
    c = hsl.withLightness(l.clamp(0.0, 1.0)).toColor();
  }
  return c;
}
