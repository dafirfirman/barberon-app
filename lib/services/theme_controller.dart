// lib/services/theme_controller.dart
//
// Pengendali tema global (gelap / terang / sistem) — supaya tema bisa diubah
// dari mana saja (mis. halaman Profil) dan langsung berlaku di seluruh aplikasi,
// termasuk setelah login. Mirip pola di aplikasi barber.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = _fromString(prefs.getString('themeMode'));
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', m.toString().split('.').last);
  }

  ThemeMode _fromString(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

// instance global
final themeController = ThemeController();