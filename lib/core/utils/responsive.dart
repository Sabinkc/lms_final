import 'package:flutter/widgets.dart';

/// Standard Material 3 window-size-class breakpoints (compact / medium /
/// expanded) — not a product-specific value, since docs/design_system.md
/// §5 explicitly flags tablet/foldable layout as out of scope pending a
/// product decision. This exists so that decision, whenever it's made, has
/// a single breakpoint definition to plug into rather than each feature
/// inventing its own.
class Breakpoints {
  Breakpoints._();

  static const double compactMax = 600;
  static const double mediumMax = 840;
}

enum WindowSizeClass { compact, medium, expanded }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  WindowSizeClass get windowSizeClass {
    final width = screenWidth;
    if (width < Breakpoints.compactMax) return WindowSizeClass.compact;
    if (width < Breakpoints.mediumMax) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }

  bool get isCompact => windowSizeClass == WindowSizeClass.compact;
  bool get isMedium => windowSizeClass == WindowSizeClass.medium;
  bool get isExpanded => windowSizeClass == WindowSizeClass.expanded;
}
