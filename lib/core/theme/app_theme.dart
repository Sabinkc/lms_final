import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Confirmed light/dark theme support (docs/design_system.md §1;
/// docs/api_spec.md gives no reason to change this). [ThemeMode.system] is
/// the default; the person can pick Light/Dark/System on the More screen
/// (`ThemeController`, saved via `LocalPrefsService`).
class AppTheme {
  AppTheme._();

  /// The hairline every card is outlined with. Exposed for widgets that
  /// give a `Card` a custom shape but should keep the standard border.
  static BorderSide cardBorderSide(Brightness brightness) =>
      BorderSide(color: AppColors.primary.withValues(alpha: brightness == Brightness.dark ? 0.35 : 0.15));

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      error: AppColors.danger,
      // Forest green leads, emerald seconds it, orange is the accent.
      primary: isDark ? const Color(0xFF5FC4D1) : AppColors.primary,
      onPrimary: isDark ? AppColors.darkBase : Colors.white,
      secondary: isDark ? const Color(0xFF34D399) : AppColors.success,
      onSecondary: isDark ? AppColors.darkBase : Colors.white,
      tertiary: isDark ? const Color(0xFFFB9A4B) : AppColors.accent,
      onTertiary: isDark ? AppColors.darkBase : Colors.white,
      surface: isDark ? AppColors.darkElevated1 : Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkBase : AppColors.lightBase,
    );

    return base.copyWith(
      textTheme: AppTypography.textTheme(
        base.textTheme,
      ).copyWith(titleLarge: AppTypography.textTheme(base.textTheme).titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        // Transparent so each screen's `AppBackground` shows through; the
        // status-bar icons are set explicitly because a transparent bar
        // would otherwise flip them to white on the light background.
        backgroundColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
      // Flat outlined cards: a thin brand-green hairline instead of a drop
      // shadow (chosen 2026-10-01 from the bordered-card previews, "B").
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: isDark ? AppColors.darkElevated2 : AppColors.lightElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card, side: cardBorderSide(brightness)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: isDark ? AppColors.darkElevated3 : colorScheme.primary.withValues(alpha: 0.08),
        labelStyle: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.primary),
        selectedColor: colorScheme.primary.withValues(alpha: isDark ? 0.34 : 0.2),
        checkmarkColor: colorScheme.primary,
      ),
      // Form dialogs: a clean white sheet (no M3 surface tint), bold title.
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkElevated2 : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        filled: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl3)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl2))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkElevated2 : AppColors.lightElevated,
        indicatorShape: const StadiumBorder(),
        indicatorColor: colorScheme.primary.withValues(alpha: isDark ? 0.24 : 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
