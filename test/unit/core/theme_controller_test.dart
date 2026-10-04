import 'package:cloud_lms/core/storage/local_prefs_service.dart';
import 'package:cloud_lms/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalPrefsService> _prefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return LocalPrefsService(await SharedPreferences.getInstance());
}

void main() {
  test('follows the phone setting until the person picks one', () async {
    expect(ThemeController(await _prefs()).mode, ThemeMode.system);
  });

  test('a picked mode applies, notifies and survives a restart', () async {
    final prefs = await _prefs();
    final controller = ThemeController(prefs);
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.setMode(ThemeMode.dark);

    expect(controller.mode, ThemeMode.dark);
    expect(notified, 1);
    expect(ThemeController(prefs).mode, ThemeMode.dark);
  });

  test('picking the current mode again does nothing', () async {
    final controller = ThemeController(await _prefs());
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.setMode(ThemeMode.system);

    expect(notified, 0);
  });

  test('an unknown saved value falls back to the phone setting', () async {
    expect(ThemeController(await _prefs({'prefs.theme_mode': 'sepia'})).mode, ThemeMode.system);
  });
}
