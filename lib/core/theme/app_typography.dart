import 'package:flutter/material.dart';

/// docs/design_system.md §2: `CONFIRMED` no custom webfont in the real web
/// source, but the doc's own recommendation (since a system-font stack
/// isn't portably meaningful across Android/iOS/web the way it is on the
/// web) is to pick a real font — Inter, as recommended — rather than chase
/// an OS-default stack. Vendored locally as a variable-font asset (see
/// `pubspec.yaml`'s `fonts:` section) rather than fetched at runtime via
/// `google_fonts`' CDN — a hard local asset has no network dependency,
/// which matters for a school app that needs to work on unreliable wifi
/// (and is deterministic in tests, unlike a runtime HTTP font fetch).
///
/// Also applies §2's confirmed weight finding: real usage is bold/semibold-
/// heavy (`font-bold` 1126 uses vs `font-normal` 9), so default body text
/// is bumped from Material's default `w400` to `w500`.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  static TextTheme textTheme(TextTheme base) {
    return base
        .copyWith(
          bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(fontFamily: fontFamily);
  }
}
