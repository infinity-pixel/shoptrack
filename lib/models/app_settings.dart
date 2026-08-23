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

class AppSettings {
  final AppTheme theme;
  final String currency;
  final String language;

  const AppSettings({
    this.theme = AppTheme.system,
    this.currency = 'BDT',
    this.language = 'English',
  });

  AppSettings copyWith({
    AppTheme? theme,
    String? currency,
    String? language,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      currency: currency ?? this.currency,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme.name,
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
      currency: json['currency'] as String? ?? 'BDT',
      language: json['language'] as String? ?? 'English',
    );
  }
}
