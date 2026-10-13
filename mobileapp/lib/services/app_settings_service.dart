import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._();
  static final AppSettingsService instance = AppSettingsService._();

  static const _darkModeKey = 'settings_dark_mode';
  static const _notificationKey = 'settings_notifications';

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier(true);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool(_darkModeKey) ?? false;
    final notifs = prefs.getBool(_notificationKey) ?? true;
    themeMode.value = darkMode ? ThemeMode.dark : ThemeMode.light;
    notificationsEnabled.value = notifs;
  }

  Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationKey, enabled);
    notificationsEnabled.value = enabled;
  }
}
