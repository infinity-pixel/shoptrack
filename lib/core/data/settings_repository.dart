import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}

class LocalSettingsRepository implements SettingsRepository {
  static const String _settingsKey = 'app_settings';

  @override
  Future<AppSettings> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_settingsKey);
      if (jsonStr == null) return const AppSettings();

      return AppSettings.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (e) {
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_settingsKey, jsonEncode(settings.toJson()))) {
      throw StateError('Could not save settings.');
    }
  }
}
