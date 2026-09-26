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
  final List<Color>? navigationIconGradient;
  final Color? calendarAccent;

  ThemeDefinition({
    required this.name,
    required this.palette,
    required this.brightness,
    required this.atmosphericConfig,
    this.headerArtworkPath,
    this.navigationIconGradient,
    this.calendarAccent,
  }) : typography = ShopTrackTypography.standard(
         brightness == Brightness.light
             ? palette.onBackground
             : palette.onBackground,
       );

  ThemeData toThemeData() {
    return ThemeData(
      fontFamilyFallback: const ['ShopTrackCurrency', 'ShopTrackRufiyaa'],
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
        onSurfaceVariant: palette.textSecondary,
        outline: palette.textSecondary,
        outlineVariant: palette.border,
      ),
      // Modal surfaces share one hierarchy in every preset. Accents belong to
      // controls; the surrounding panel stays quiet and theme-aware.
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: brightness == Brightness.dark
          ? InputDecorationTheme(
              filled: true,
              fillColor: Color.alphaBlend(
                palette.onSurface.withValues(alpha: .055),
                palette.surface,
              ),
              labelStyle: TextStyle(color: palette.textSecondary),
              hintStyle: TextStyle(color: palette.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: palette.textSecondary.withValues(alpha: 0.65),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.primary, width: 2),
              ),
            )
          : null,
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
          navigationIconGradient: navigationIconGradient,
          calendarAccent: calendarAccent,
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
      name: 'Golden Summer',
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
        surfaceReceipt: const Color(0xFFFFFBED),
        receiptEdge: const Color(0xFFF0D797),
        receiptShadow: const Color(0x402F1E0B),
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
      headerArtworkPath: 'assets/images/theme_light_golden_summer.webp',
    ),
    LightPreset.spring: ThemeDefinition(
      name: 'Blooming Spring',
      brightness: Brightness.light,
      palette: ShopTrackPalette.light(
        primary: const Color(0xFF9C3E68),
        secondary: const Color(0xFF3D785E),
        today: const Color(0xFF9C3E68),
        purchased: const Color(0xFF1F5636),
        pending: const Color(0xFFB3261E),
        planned: const Color(0xFF6E4D9A),
        background: const Color(0xFFF2F8F0),
        surface: const Color(0xFFFFFCFD),
        surfaceToBuy: const Color(0xFFFFFBFD),
        surfacePurchased: const Color(0xFFE3F3E8),
        border: const Color(0xFFD4E3D6),
        onBackground: const Color(0xFF25352B),
        textSecondary: const Color(0xFF55685C),
        surfaceReceipt: const Color(0xFFFFF5F8),
        receiptEdge: const Color(0xFFE9C6D5),
        receiptShadow: const Color(0x4020392A),
      ),
      atmosphericConfig: const AtmosphericConfig(
        baseColor: Color(0xFFF2F8F0),
        gradientColors: [
          Color(0xFFF5DCE7),
          Color(0xFFF8FBF5),
          Color(0xFFD9EFDC),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        opacity: 0.42,
      ),
      headerArtworkPath: 'assets/images/theme_light_blooming_spring.webp',
      navigationIconGradient: const [
        Color(0xFF397A5D),
        Color(0xFFB94F7A),
        Color(0xFF76569B),
      ],
      calendarAccent: const Color(0xFFB94F7A),
    ),
    LightPreset.ocean: ThemeDefinition(
      name: 'Tranquil Ocean',
      brightness: Brightness.light,
      palette: ShopTrackPalette.light(
        primary: const Color(0xFF006B8F),
        secondary: const Color(0xFF00767D),
        today: const Color(0xFF006B9E),
        purchased: const Color(0xFF0D503B),
        pending: const Color(0xFFA32932),
        planned: const Color(0xFF5B4BA1),
        background: const Color(0xFFEAF7FA),
        surface: const Color(0xFFF9FEFF),
        surfaceToBuy: const Color(0xFFF4FCFE),
        surfacePurchased: const Color(0xFFE3F4EF),
        border: const Color(0xFFB9DBE4),
        onBackground: const Color(0xFF173642),
        textSecondary: const Color(0xFF476773),
        surfaceReceipt: const Color(0xFFF0FAF8),
        receiptEdge: const Color(0xFF9FCFD6),
        receiptShadow: const Color(0x40203943),
      ),
      atmosphericConfig: const AtmosphericConfig(
        baseColor: Color(0xFFEAF7FA),
        gradientColors: [
          Color(0xFFC9EAF3),
          Color(0xFFF6FCFD),
          Color(0xFFBDE3EB),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        opacity: 0.4,
      ),
      headerArtworkPath: 'assets/images/theme_light_tranquil_ocean.webp',
    ),
    LightPreset.autumn: ThemeDefinition(
      name: 'Ember Autumn',
      brightness: Brightness.light,
      palette: ShopTrackPalette.light(
        primary: const Color(0xFFB85C38),
        secondary: const Color(0xFFA34A2A),
        today: const Color(0xFFA94B2F),
        purchased: const Color(0xFF235A34),
        pending: const Color(0xFFB3261E),
        planned: const Color(0xFF7B3F84),
        background: const Color(0xFFFFF3E6),
        surface: const Color(0xFFFFFCF7),
        surfaceToBuy: const Color(0xFFFFFCF7),
        surfacePurchased: const Color(0xFFEDF5E8),
        border: const Color(0xFFE8D3BF),
        onBackground: const Color(0xFF3C2A20),
        textSecondary: const Color(0xFF705F54),
        surfaceReceipt: const Color(0xFFFFF4D8),
        receiptEdge: const Color(0xFFE6B96F),
        receiptShadow: const Color(0x402D1B10),
      ),
      atmosphericConfig: const AtmosphericConfig(
        baseColor: Color(0xFFFFF3E6),
        gradientColors: [
          Color(0xFFF6D2A7),
          Color(0xFFFFF6EB),
          Color(0xFFF3C99D),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        opacity: 0.38,
      ),
      headerArtworkPath: 'assets/images/theme_light_ember_autumn.webp',
    ),
  };

  /// Map of Dark Presets
  static final Map<DarkPreset, ThemeDefinition> darkPresets = {
    DarkPreset.midnight: ThemeDefinition(
      name: 'Silent Midnight',
      brightness: Brightness.dark,
      palette: const ShopTrackPalette(
        primary: Color(0xFFA6AEF5),
        secondary: Color(0xFFADB6F5),
        background: Color(0xFF111318),
        surface: Color(0xFF252932),
        error: Color(0xFFF099A1),
        onPrimary: Color(0xFF171B35),
        onSecondary: Color(0xFF171B35),
        onBackground: Color(0xFFF5F5FA),
        onSurface: Color(0xFFF5F5FA),
        onError: Color(0xFF321419),
        purchased: Color(0xFF89C49B),
        pending: Color(0xFFF099A1),
        planned: Color(0xFFC9A5E8),
        today: Color(0xFFADB6F5),
        onStatus: Color(0xFF111318),
        surfaceToBuy: Color(0xFF252932),
        surfacePurchased: Color(0xFF24332D),
        border: Color(0xFF383D49),
        textSecondary: Color(0xFFB0B5C3),
        surfaceReceipt: Color(0xFF252936),
        receiptEdge: Color(0xFF343B50),
        receiptShadow: Color(0x66000000),
      ),
      atmosphericConfig: const AtmosphericConfig(
        baseColor: Color(0xFF111318),
        gradientColors: [
          Color(0xFF252A3C),
          Color(0xFF111318),
          Color(0xFF202430),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        opacity: 0.22,
      ),
      headerArtworkPath: 'assets/images/theme_dark_silent_midnight.webp',
    ),
    DarkPreset.aurora: ThemeDefinition(
      name: 'Ethereal Aurora',
      brightness: Brightness.dark,
      palette: const ShopTrackPalette(
        primary: Color(0xFF66D7B0),
        secondary: Color(0xFFB5A1E8),
        background: Color(0xFF091514),
        surface: Color(0xFF203431),
        error: Color(0xFFF49A9A),
        onPrimary: Color(0xFF06231A),
        onSecondary: Color(0xFF181029),
        onBackground: Color(0xFFF1F7F5),
        onSurface: Color(0xFFF1F7F5),
        onError: Color(0xFF321414),
        purchased: Color(0xFF7FD5A2),
        pending: Color(0xFFF49A9A),
        planned: Color(0xFFC7B1F4),
        today: Color(0xFF69DCC0),
        onStatus: Color(0xFF071513),
        surfaceToBuy: Color(0xFF263D39),
        surfacePurchased: Color(0xFF204035),
        border: Color(0xFF38524E),
        textSecondary: Color(0xFFAABDB7),
        surfaceReceipt: Color(0xFF223836),
        receiptEdge: Color(0xFF294744),
        receiptShadow: Color(0x73000000),
      ),
      atmosphericConfig: const AtmosphericConfig(
        baseColor: Color(0xFF091514),
        gradientColors: [
          Color(0xFF0C211D),
          Color(0xFF091514),
          Color(0xFF17152A),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        opacity: 1,
      ),
      headerArtworkPath: 'assets/images/theme_dark_ethereal_aurora.webp',
      navigationIconGradient: const [
        Color(0xFF66D7B0),
        Color(0xFF8FD9CB),
        Color(0xFFB5A1E8),
      ],
    ),
    DarkPreset.moonlit: ThemeDefinition(
      name: 'Bleeding Moonlight',
      brightness: Brightness.dark,
      palette: const ShopTrackPalette(
        primary: Color(0xFFD65D5D),
        secondary: Color(0xFFE58A7E),
        background: Color(0xFF0D090B),
        surface: Color(0xFF281A1E),
        error: Color(0xFFF6A0A0),
        onPrimary: Color(0xFF2A090B),
        onSecondary: Color(0xFF2A090B),
        onBackground: Color(0xFFF8EEEE),
        onSurface: Color(0xFFF8EEEE),
        onError: Color(0xFF321011),
        purchased: Color(0xFF8AD0A6),
        pending: Color(0xFFF2A0A0),
        planned: Color(0xFFD8A4D5),
        today: Color(0xFFED8880),
        onStatus: Color(0xFF25090B),
        surfaceToBuy: Color(0xFF302024),
        surfacePurchased: Color(0xFF203129),
        border: Color(0xFF4B3338),
        textSecondary: Color(0xFFC9AFB4),
        surfaceReceipt: Color(0xFF2B1C20),
        receiptEdge: Color(0xFF4A3035),
        receiptShadow: Color(0x80000000),
      ),
      atmosphericConfig: const AtmosphericConfig(
        baseColor: Color(0xFF0D090B),
        gradientColors: [
          Color(0xFF160B0F),
          Color(0xFF0D090B),
          Color(0xFF18090D),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        opacity: 1,
      ),
      headerArtworkPath: 'assets/images/theme_dark_bleeding_moonlight.webp',
    ),
    DarkPreset.deepForest: ThemeDefinition(
      name: 'Ancient Forest',
      brightness: Brightness.dark,
      palette: const ShopTrackPalette(
        primary: Color(0xFFA8C47F),
        secondary: Color(0xFFD0A15B),
        background: Color(0xFF0C120F),
        surface: Color(0xFF202A23),
        error: Color(0xFFF2A0A0),
        onPrimary: Color(0xFF17200E),
        onSecondary: Color(0xFF251708),
        onBackground: Color(0xFFF0F4EC),
        onSurface: Color(0xFFF0F4EC),
        onError: Color(0xFF321414),
        purchased: Color(0xFF9AC795),
        pending: Color(0xFFF1A09A),
        planned: Color(0xFFD6B27A),
        today: Color(0xFFD0A15B),
        onStatus: Color(0xFF151B12),
        surfaceToBuy: Color(0xFF263229),
        surfacePurchased: Color(0xFF213329),
        border: Color(0xFF3C4B40),
        textSecondary: Color(0xFFB7C2B3),
        surfaceReceipt: Color(0xFF29291F),
        receiptEdge: Color(0xFF4A4631),
        receiptShadow: Color(0x80000000),
      ),
      atmosphericConfig: const AtmosphericConfig(
        baseColor: Color(0xFF0C120F),
        gradientColors: [
          Color(0xFF132119),
          Color(0xFF0C120F),
          Color(0xFF1B1A12),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        opacity: 1,
      ),
      headerArtworkPath: 'assets/images/theme_dark_ancient_forest.webp',
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
  final List<Color>? navigationIconGradient;
  final Color? calendarAccent;

  const ShopTrackThemeTokens({
    required this.palette,
    this.headerArtworkPath,
    this.navigationIconGradient,
    this.calendarAccent,
  });

  static ShopTrackThemeTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<ShopTrackThemeTokens>();
    assert(tokens != null, 'ShopTrack theme tokens are required.');
    return tokens!;
  }

  @override
  ShopTrackThemeTokens copyWith({
    ShopTrackPalette? palette,
    String? headerArtworkPath,
    List<Color>? navigationIconGradient,
    Color? calendarAccent,
  }) => ShopTrackThemeTokens(
    palette: palette ?? this.palette,
    headerArtworkPath: headerArtworkPath ?? this.headerArtworkPath,
    navigationIconGradient:
        navigationIconGradient ?? this.navigationIconGradient,
    calendarAccent: calendarAccent ?? this.calendarAccent,
  );

  @override
  ShopTrackThemeTokens lerp(ShopTrackThemeTokens? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}
