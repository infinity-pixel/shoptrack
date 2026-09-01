enum AppTheme {
  system,
  light,
  dark;

  String get displayName {
    switch (this) {
      case AppTheme.system:
        return 'System Default';
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
        return 'Summer';
      case LightPreset.spring:
        return 'Spring';
      case LightPreset.ocean:
        return 'Ocean';
      case LightPreset.autumn:
        return 'Autumn';
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
        return 'Midnight';
      case DarkPreset.aurora:
        return 'Aurora';
      case DarkPreset.moonlit:
        return 'Moonlit';
      case DarkPreset.deepForest:
        return 'Deep Forest';
    }
  }
}

class AppSettings {
  final AppTheme theme;
  final LightPreset lightPreset;
  final DarkPreset darkPreset;
  final String currency;
  final String language;

  const AppSettings({
    this.theme = AppTheme.system,
    this.lightPreset = LightPreset.summer,
    this.darkPreset = DarkPreset.midnight,
    this.currency = 'BDT',
    this.language = 'English',
  });

  AppSettings copyWith({
    AppTheme? theme,
    LightPreset? lightPreset,
    DarkPreset? darkPreset,
    String? currency,
    String? language,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      lightPreset: lightPreset ?? this.lightPreset,
      darkPreset: darkPreset ?? this.darkPreset,
      currency: currency ?? this.currency,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme.name,
      'lightPreset': lightPreset.name,
      'darkPreset': darkPreset.name,
      'currency': currency,
      'language': language,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
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
      currency: json['currency'] as String? ?? 'BDT',
      language: json['language'] as String? ?? 'English',
    );
  }
}
