import 'package:flutter/material.dart';

import '../storage/local_prefs_service.dart';

/// The person's light/dark choice, saved on the device. Defaults to
/// following the phone's own setting.
class ThemeController extends ChangeNotifier {
  final LocalPrefsService _prefs;
  ThemeMode _mode;

  ThemeController(this._prefs) : _mode = _parse(_prefs.themeMode);

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setThemeMode(mode.name);
  }

  static ThemeMode _parse(String? raw) =>
      ThemeMode.values.firstWhere((m) => m.name == raw, orElse: () => ThemeMode.system);
}
