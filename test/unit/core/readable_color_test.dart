import 'package:cloud_lms/core/theme/app_colors.dart';
import 'package:cloud_lms/core/theme/readable_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('light mode leaves colours unchanged', () {
    expect(readableColor(AppColors.primary, Brightness.light), AppColors.primary);
  });

  test('dark mode lifts brand colours to AA contrast on the dark base', () {
    for (final c in [AppColors.primary, AppColors.info, AppColors.danger, const Color(0xFF16A34A)]) {
      expect(_contrast(readableColor(c, Brightness.dark), AppColors.darkBase), greaterThanOrEqualTo(4.5));
    }
  });

  test('already-light colours are left alone in dark mode', () {
    expect(readableColor(Colors.white, Brightness.dark), Colors.white);
  });
}
