import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;

  String get modeKey {
    switch (_mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.system: return 'system';
      default: return 'dark';
    }
  }

  void setMode(String key) {
    switch (key) {
      case 'light': _mode = ThemeMode.light; break;
      case 'system': _mode = ThemeMode.system; break;
      default: _mode = ThemeMode.dark;
    }
    notifyListeners();
  }
}
