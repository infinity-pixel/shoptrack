import 'package:flutter/material.dart';

import '../core/currency/currency_catalog.dart';
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

  Future<void> updateLightPreset(LightPreset preset) async {
    _settings = _settings.copyWith(lightPreset: preset);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateDarkPreset(DarkPreset preset) async {
    _settings = _settings.copyWith(darkPreset: preset);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateCurrency(String currency) async {
    final normalized = CurrencyCatalog.normalizeDefaultCode(currency);
    _settings = _settings.copyWith(
      currency: normalized,
      recentCurrencies: CurrencyCatalog.sanitizeRecentCodes(
        _settings.recentCurrencies,
        defaultCurrencyCode: normalized,
      ),
    );
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateNumberFormat(NumberFormatPreference preference) async {
    _settings = _settings.copyWith(numberFormat: preference);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> recordRecentCurrency(String currency) async {
    final updated = _settings.recordRecentCurrency(currency);
    if (identical(updated, _settings)) return;
    _settings = updated;
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateLanguage(String language) async {
    final updated = _settings.copyWith(language: language);
    await _repository.saveSettings(updated);
    _settings = updated;
    notifyListeners();
  }

  int _dataToken = 0;
  int get dataToken => _dataToken;

  void notifyDataRestored() {
    _dataToken++;
    notifyListeners();
  }
}
