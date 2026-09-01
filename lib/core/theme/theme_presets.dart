import 'package:flutter/material.dart';
import '../../models/app_settings.dart';
import 'design_system.dart';

/// Configuration for the atmospheric background of a theme.
class AtmosphericConfig {
  final List<Color> gradientColors;
  final Color? baseColor;
  final Alignment begin;
  final Alignment end;
  final double opacity;

  const AtmosphericConfig({
    required this.gradientColors,
    this.baseColor,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.opacity = 0.05,
  });
}

/// A complete definition of a ShopTrack theme preset.
class ThemeDefinition {
  final String name;
  final ShopTrackPalette palette;
  final ShopTrackTypography typography;
  final AtmosphericConfig atmosphericConfig;
  final Brightness brightness;
  final String? headerArtworkPath;

  ThemeDefinition({
    required this.name,
    required this.palette,
    required this.brightness,
    required this.atmosphericConfig,
    this.headerArtworkPath,
  }) : typography = ShopTrackTypography.standard(
         brightness == Brightness.light
             ? palette.onBackground
             : palette.onBackground,
       );

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: palette.primary,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: brightness,
        primary: palette.primary,
        secondary: palette.secondary,
        surface: palette.surface,
        error: palette.error,
        onPrimary: palette.onPrimary,
        onSecondary: palette.onSecondary,
        onSurface: palette.onSurface,
        onError: palette.onError,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: typography.sectionTitle,
        iconTheme: IconThemeData(color: palette.onBackground),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.onSurface.withValues(alpha: 0.5),
        selectedLabelStyle: typography.navLabel,
        unselectedLabelStyle: typography.navLabel,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ShopTrackDesignSystem.radius.medium,
          ),
          side: BorderSide(color: palette.onSurface.withValues(alpha: 0.05)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ShopTrackDesignSystem.radius.large,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          textStyle: typography.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ShopTrackDesignSystem.radius.medium,
            ),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      extensions: [
        ShopTrackThemeTokens(
          palette: palette,
          headerArtworkPath: headerArtworkPath,
        ),
      ],
    );
  }
}

class ThemePresets {
  ThemePresets._();

  /// Map of Light Presets
  static final Map<LightPreset, ThemeDefinition> lightPresets = {
    LightPreset.summer: ThemeDefinition(
      name: 'Summer',
      brightness: Brightness.light,
      palette: ShopTrackPalette.light(
        primary: const Color(0xFFFFB44D),
        secondary: const Color(0xFFF48C06),
        today: const Color(0xFFF48C06),
        purchased: const Color(0xFF2E7D32),
        background: const Color(0xFFFFF3E1),
        surface: const Color(0xFFFFFDFA),
        surfaceToBuy: const Color(0xFFFFFDFA),
        surfacePurchased: const Color(0xFFE8F6EA),
        border: const Color(0xFFF1E2C6),
        onBackground: const Color(0xFF3E2E1F),
        textSecondary: const Color(0xFF6B6B6B),
      ),
      atmosphericConfig: const AtmosphericConfig(
        baseColor: Color(0xFFFFF3E1),
        gradientColors: [
          Color(0xFFF8D99D),
          Color(0xFFFFF7EA),
          Color(0xFFF8D99D),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        opacity: 0.38,
      ),
      headerArtworkPath: 'assets/images/theme_light_summer.webp',
    ),
    LightPreset.spring: ThemeDefinition(
      name: 'Spring',
      brightness: Brightness.light,
      palette: ShopTrackPalette.light(
        primary: const Color(0xFF4CAF50), // Fresh green
        today: const Color(0xFF8BC34A),
      ),
      atmosphericConfig: const AtmosphericConfig(
        gradientColors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
        opacity: 0.12,
      ),
    ),
    LightPreset.ocean: ThemeDefinition(
      name: 'Ocean',
      brightness: Brightness.light,
      palette: ShopTrackPalette.light(
        primary: const Color(0xFF0277BD), // Deep sea blue
        today: const Color(0xFF4FC3F7),
      ),
      atmosphericConfig: const AtmosphericConfig(
        gradientColors: [Color(0xFFE1F5FE), Color(0xFFE0F7FA)],
        opacity: 0.15,
      ),
    ),
    LightPreset.autumn: ThemeDefinition(
      name: 'Autumn',
      brightness: Brightness.light,
      palette: ShopTrackPalette.light(
        primary: const Color(0xFF8D6E63), // Earthy brown
        today: const Color(0xFFD84315), // Burnt orange
      ),
      atmosphericConfig: const AtmosphericConfig(
        gradientColors: [Color(0xFFEFEBE9), Color(0xFFFBE9E7)],
        opacity: 0.1,
      ),
    ),
  };

  /// Map of Dark Presets
  static final Map<DarkPreset, ThemeDefinition> darkPresets = {
    DarkPreset.midnight: ThemeDefinition(
      name: 'Midnight',
      brightness: Brightness.dark,
      palette: ShopTrackPalette.dark(
        primary: const Color(0xFF7986CB), // Indigo light
        today: const Color(0xFF3949AB),
      ),
      atmosphericConfig: const AtmosphericConfig(
        gradientColors: [Color(0xFF1A237E), Color(0xFF000051)],
        opacity: 0.2,
      ),
    ),
    DarkPreset.aurora: ThemeDefinition(
      name: 'Aurora',
      brightness: Brightness.dark,
      palette: ShopTrackPalette.dark(
        primary: const Color(0xFF26A69A), // Teal
        today: const Color(0xFF00897B),
      ),
      atmosphericConfig: const AtmosphericConfig(
        gradientColors: [Color(0xFF004D40), Color(0xFF1B5E20)],
        opacity: 0.15,
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ),
    ),
    DarkPreset.moonlit: ThemeDefinition(
      name: 'Moonlit',
      brightness: Brightness.dark,
      palette: ShopTrackPalette.dark(
        primary: const Color(0xFFB0BEC5), // Grey blue
        today: const Color(0xFF546E7A),
      ),
      atmosphericConfig: const AtmosphericConfig(
        gradientColors: [Color(0xFF263238), Color(0xFF212121)],
        opacity: 0.25,
      ),
    ),
    DarkPreset.deepForest: ThemeDefinition(
      name: 'Deep Forest',
      brightness: Brightness.dark,
      palette: ShopTrackPalette.dark(
        primary: const Color(0xFF81C784), // Pale green
        today: const Color(0xFF2E7D32),
      ),
      atmosphericConfig: const AtmosphericConfig(
        gradientColors: [Color(0xFF1B5E20), Color(0xFF002400)],
        opacity: 0.2,
      ),
    ),
  };

  static ThemeDefinition getDefinition(
    AppSettings settings,
    Brightness platformBrightness,
  ) {
    final bool isDark =
        settings.theme == AppTheme.dark ||
        (settings.theme == AppTheme.system &&
            platformBrightness == Brightness.dark);

    if (isDark) {
      return darkPresets[settings.darkPreset] ??
          darkPresets[DarkPreset.midnight]!;
    } else {
      return lightPresets[settings.lightPreset] ??
          lightPresets[LightPreset.summer]!;
    }
  }
}

@immutable
class ShopTrackThemeTokens extends ThemeExtension<ShopTrackThemeTokens> {
  final ShopTrackPalette palette;
  final String? headerArtworkPath;

  const ShopTrackThemeTokens({required this.palette, this.headerArtworkPath});

  static ShopTrackThemeTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<ShopTrackThemeTokens>();
    assert(tokens != null, 'ShopTrack theme tokens are required.');
    return tokens!;
  }

  @override
  ShopTrackThemeTokens copyWith({
    ShopTrackPalette? palette,
    String? headerArtworkPath,
  }) => ShopTrackThemeTokens(
    palette: palette ?? this.palette,
    headerArtworkPath: headerArtworkPath ?? this.headerArtworkPath,
  );

  @override
  ShopTrackThemeTokens lerp(ShopTrackThemeTokens? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}
