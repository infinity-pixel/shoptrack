import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/data/settings_repository.dart';
import 'package:shoptrack/models/app_settings.dart';
import 'package:shoptrack/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 11: Settings Architecture & Persistence', () {
    late SettingsRepository repository;
    late SettingsService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = LocalSettingsRepository();
      service = SettingsService(repository);
    });

    test('Default settings are correctly established', () {
      const settings = AppSettings();
      expect(settings.theme, AppTheme.system);
      expect(settings.currency, 'BDT');
      expect(settings.language, 'English');
    });

    test('Settings loading returns defaults if nothing saved', () async {
      await service.loadSettings();
      expect(service.settings.theme, AppTheme.system);
      expect(service.isInitialized, isTrue);
    });

    test('Theme preference persistence works', () async {
      await service.loadSettings();
      await service.updateTheme(AppTheme.dark);
      
      expect(service.settings.theme, AppTheme.dark);
      
      // Reload from repository to verify persistence
      final newRepository = LocalSettingsRepository();
      final loadedSettings = await newRepository.getSettings();
      expect(loadedSettings.theme, AppTheme.dark);
    });

    test('Currency preference placeholder persists correctly', () async {
      await service.loadSettings();
      await service.updateCurrency('USD');
      expect(service.settings.currency, 'USD');
      
      final loadedSettings = await repository.getSettings();
      expect(loadedSettings.currency, 'USD');
    });

    test('Language preference placeholder persists correctly', () async {
      await service.loadSettings();
      await service.updateLanguage('Spanish');
      expect(service.settings.language, 'Spanish');
      
      final loadedSettings = await repository.getSettings();
      expect(loadedSettings.language, 'Spanish');
    });

    test('AppSettings copyWith creates a new instance with updated values', () {
      const settings = AppSettings();
      final updated = settings.copyWith(theme: AppTheme.light, currency: 'EUR');
      
      expect(updated.theme, AppTheme.light);
      expect(updated.currency, 'EUR');
      expect(updated.language, 'English'); // Preserved
      expect(settings.theme, AppTheme.system); // Original unchanged
    });

    test('AppSettings serialization/deserialization preserves all fields', () {
      const settings = AppSettings(
        theme: AppTheme.dark,
        currency: 'GBP',
        language: 'French',
      );
      
      final json = settings.toJson();
      final reconstructed = AppSettings.fromJson(json);
      
      expect(reconstructed.theme, settings.theme);
      expect(reconstructed.currency, settings.currency);
      expect(reconstructed.language, settings.language);
    });
  });
}
