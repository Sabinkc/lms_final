import 'package:flutter/material.dart';

/// Switched 2026-09-14 from Inter to Plus Jakarta Sans to match the
/// "Verdant Scholar" design system used throughout the Google Stitch
/// mockups (`docs/stitch_screens/`) — every exported screen's tailwind
/// config specifies `Plus Jakarta Sans` as its only font family. Vendored
/// locally as a variable-font asset (see `pubspec.yaml`'s `fonts:` section)
/// the same way Inter was, rather than fetched at runtime via
/// `google_fonts`' CDN — a hard local asset has no network dependency,
/// which matters for a school app that needs to work on unreliable wifi
/// (and is deterministic in tests, unlike a runtime HTTP font fetch).
///
/// Weight usage still follows docs/design_system.md §2's confirmed real-
/// web finding (bold/semibold-heavy), and the Stitch mockups independently
/// confirm the same pattern (`font-bold`/`font-semibold` on nearly every
/// text style token) — so default body text stays bumped from Material's
/// default `w400` to `w500`.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'PlusJakartaSans';

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
