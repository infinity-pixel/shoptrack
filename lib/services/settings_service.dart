import 'package:flutter/material.dart';

import '../core/currency/currency_catalog.dart';
import '../core/data/settings_repository.dart';
import '../models/app_settings.dart';

class SettingsService extends ChangeNotifier {
  final SettingsRepository _repository;
  AppSettings _settings = const AppSettings();
  bool _isInitialized = false;
  bool _isSwitchingLanguage = false;

  SettingsService(this._repository);

  AppSettings get settings => _settings;
  bool get isInitialized => _isInitialized;
  bool get isSwitchingLanguage => _isSwitchingLanguage;

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
    await _save(_settings.copyWith(theme: theme));
  }

  Future<void> updateLightPreset(LightPreset preset) async {
    await _save(_settings.copyWith(lightPreset: preset));
  }

  Future<void> updateDarkPreset(DarkPreset preset) async {
    await _save(_settings.copyWith(darkPreset: preset));
  }

  Future<void> updateCurrency(String currency) async {
    final normalized = CurrencyCatalog.normalizeDefaultCode(currency);
    final updated = _settings.copyWith(
      currency: normalized,
      recentCurrencies: CurrencyCatalog.sanitizeRecentCodes(
        _settings.recentCurrencies,
        defaultCurrencyCode: normalized,
      ),
    );
    await _save(updated);
  }

  Future<void> updateNumberFormat(NumberFormatPreference preference) async {
    await _save(_settings.copyWith(numberFormat: preference));
  }

  Future<void> recordRecentCurrency(String currency) async {
    final updated = _settings.recordRecentCurrency(currency);
    if (identical(updated, _settings)) return;
    await _save(updated);
  }

  Future<void> updateLanguage(
    String language, {
    Future<void> Function()? waitForFrame,
  }) async {
    if (_isSwitchingLanguage || _settings.language == language) return;
    if (!const ['English', 'Bangla', 'Arabic'].contains(language)) {
      throw ArgumentError.value(language, 'language');
    }
    _isSwitchingLanguage = true;
    notifyListeners();
    try {
      // Let the busy overlay paint before changing locale and direction. There
      // is no artificial delay; it stays until the new interface has a frame.
      await waitForFrame?.call();
      final updated = _settings.copyWith(language: language);
      await _repository.saveSettings(updated);
      _settings = updated;
      notifyListeners();
      await waitForFrame?.call();
    } finally {
      _isSwitchingLanguage = false;
      notifyListeners();
    }
  }

  Future<void> updateCalendar(
    CalendarPreference calendar,
    int hijriAdjustment,
  ) async {
    final updated = _settings.copyWith(
      calendar: calendar,
      hijriAdjustment: hijriAdjustment,
    );
    await _save(updated);
  }

  Future<void> _save(AppSettings updated) async {
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
