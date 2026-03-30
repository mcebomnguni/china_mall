import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDarkMode = 'pref_dark_mode';

/// Single source of truth for the app-wide theme mode.
///
/// Registered in main.dart's MultiProvider so any widget can:
///   context.read(ThemeNotifier).setDark(true);   // change + persist
///   context.watch(ThemeNotifier).isDark;          // read reactively
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode   => _mode;
  bool      get isDark => _mode == ThemeMode.dark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = (prefs.getBool(_kDarkMode) ?? false)
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, dark);
  }

  Future<void> toggle() => setDark(!isDark);
}
