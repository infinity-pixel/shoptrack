import '../core/currency/currency_catalog.dart';

enum AppTheme {
  system,
  light,
  dark;

  String get displayName {
    switch (this) {
      case AppTheme.system:
        return 'System';
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
    }
  }
}

enum LightPreset {
  summer,
  spring,
  ocean,
  autumn;

  String get displayName {
    switch (this) {
      case LightPreset.summer:
        return 'Golden Summer';
      case LightPreset.spring:
        return 'Blooming Spring';
      case LightPreset.ocean:
        return 'Tranquil Ocean';
      case LightPreset.autumn:
        return 'Ember Autumn';
    }
  }
}

enum DarkPreset {
  midnight,
  aurora,
  moonlit,
  deepForest;

  String get displayName {
    switch (this) {
      case DarkPreset.midnight:
        return 'Silent Midnight';
      case DarkPreset.aurora:
        return 'Ethereal Aurora';
      case DarkPreset.moonlit:
        return 'Bleeding Moonlight';
      case DarkPreset.deepForest:
        return 'Ancient Forest';
    }
  }
}

class AppSettings {
  final AppTheme theme;
  final LightPreset lightPreset;
  final DarkPreset darkPreset;
  final String currency;
  final List<String> recentCurrencies;
  final String language;

  const AppSettings({
    this.theme = AppTheme.system,
    this.lightPreset = LightPreset.summer,
    this.darkPreset = DarkPreset.midnight,
    this.currency = CurrencyCatalog.defaultCode,
    this.recentCurrencies = const [],
    this.language = 'English',
  });

  AppSettings copyWith({
    AppTheme? theme,
    LightPreset? lightPreset,
    DarkPreset? darkPreset,
    String? currency,
    List<String>? recentCurrencies,
    String? language,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      lightPreset: lightPreset ?? this.lightPreset,
      darkPreset: darkPreset ?? this.darkPreset,
      currency: currency ?? this.currency,
      recentCurrencies: recentCurrencies ?? this.recentCurrencies,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme.name,
      'lightPreset': lightPreset.name,
      'darkPreset': darkPreset.name,
      'currency': currency,
      'recentCurrencies': recentCurrencies,
      'language': language,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final currency = CurrencyCatalog.normalizeDefaultCode(json['currency']);
    final recentJson = json['recentCurrencies'];
    return AppSettings(
      theme: AppTheme.values.firstWhere(
        (e) => e.name == json['theme'],
        orElse: () => AppTheme.system,
      ),
      lightPreset: LightPreset.values.firstWhere(
        (e) => e.name == json['lightPreset'],
        orElse: () => LightPreset.summer,
      ),
      darkPreset: DarkPreset.values.firstWhere(
        (e) => e.name == json['darkPreset'],
        orElse: () => DarkPreset.midnight,
      ),
      currency: currency,
      recentCurrencies: CurrencyCatalog.sanitizeRecentCodes(
        recentJson is List ? recentJson : const [],
        defaultCurrencyCode: currency,
      ),
      language: json['language'] as String? ?? 'English',
    );
  }

  AppSettings recordRecentCurrency(String code) {
    final normalized = CurrencyCatalog.normalizeItemCode(code);
    if (!CurrencyCatalog.isSupported(normalized) || normalized == currency) {
      return this;
    }
    return copyWith(
      recentCurrencies: CurrencyCatalog.sanitizeRecentCodes([
        normalized,
        ...recentCurrencies,
      ], defaultCurrencyCode: currency),
    );
  }
}
