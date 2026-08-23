import 'package:flutter/material.dart';
import '../core/data/settings_repository.dart';
import '../models/app_settings.dart';

class SettingsService extends ChangeNotifier {
  final SettingsRepository _repository;
  AppSettings _settings = const AppSettings();
  bool _isInitialized = false;

  SettingsService(this._repository);

  AppSettings get settings => _settings;
  bool get isInitialized => _isInitialized;

  ThemeMode get themeMode {
    switch (_settings.theme) {
      case AppTheme.system:
        return ThemeMode.system;
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
    }
  }

  Future<void> loadSettings() async {
    _settings = await _repository.getSettings();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> updateTheme(AppTheme theme) async {
    _settings = _settings.copyWith(theme: theme);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateCurrency(String currency) async {
    _settings = _settings.copyWith(currency: currency);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateLanguage(String language) async {
    _settings = _settings.copyWith(language: language);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }
}
