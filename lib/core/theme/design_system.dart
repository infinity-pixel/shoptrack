import 'package:flutter/material.dart';

/// Centralized design tokens for the ShopTrack application.
class ShopTrackDesignSystem {
  ShopTrackDesignSystem._();

  /// Spacing tokens following a consistent scale.
  static const spacing = ShopTrackSpacing();

  /// Radius tokens for consistent rounding.
  static const radius = ShopTrackRadius();

  /// Motion tokens for consistent animations.
  static const motion = ShopTrackMotion();
}

class ShopTrackSpacing {
  const ShopTrackSpacing();

  final double tiny = 4.0;
  final double small = 8.0;
  final double medium = 16.0;
  final double large = 24.0;
  final double xLarge = 32.0;
  final double section = 24.0;
  final double screenPadding = 16.0;
}

class ShopTrackRadius {
  const ShopTrackRadius();

  final double small = 8.0;
  final double medium = 12.0;
  final double large = 16.0;
  final double xLarge = 24.0;
  final double circular = 100.0;
}

class ShopTrackMotion {
  const ShopTrackMotion();

  final Duration short = const Duration(milliseconds: 200);
  final Duration medium = const Duration(milliseconds: 400);
  final Duration long = const Duration(milliseconds: 600);

  final Curve curve = Curves.easeInOut;
  final Curve emphasizedCurve = Curves.easeOutBack;
}

/// Semantic color palette for ShopTrack.
/// These colors adapt to light and dark themes.
class ShopTrackPalette {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color error;
  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onSurface;
  final Color onError;

  // Semantic Status Colors
  final Color purchased;
  final Color pending;
  final Color planned;
  final Color today;
  final Color onStatus;

  /// Theme-aware visual surfaces used by the shopping lists.
  final Color surfaceToBuy;
  final Color surfacePurchased;
  final Color border;
  final Color textSecondary;

  const ShopTrackPalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.error,
    required this.onPrimary,
    required this.onSecondary,
    required this.onBackground,
    required this.onSurface,
    required this.onError,
    required this.purchased,
    required this.pending,
    required this.planned,
    required this.today,
    required this.onStatus,
    required this.surfaceToBuy,
    required this.surfacePurchased,
    required this.border,
    required this.textSecondary,
  });

  /// Standard Light Palette Foundation
  factory ShopTrackPalette.light({
    required Color primary,
    Color? secondary,
    Color? purchased,
    Color? pending,
    Color? planned,
    Color? today,
    Color? background,
    Color? surface,
    Color? surfaceToBuy,
    Color? surfacePurchased,
    Color? border,
    Color? onBackground,
    Color? textSecondary,
  }) {
    return ShopTrackPalette(
      primary: primary,
      secondary: secondary ?? primary.withValues(alpha: 0.7),
      background: background ?? const Color(0xFFF8F9FA),
      surface: surface ?? Colors.white,
      error: const Color(0xFFD32F2F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: onBackground ?? const Color(0xFF212529),
      onSurface: onBackground ?? const Color(0xFF212529),
      onError: Colors.white,
      purchased: purchased ?? const Color(0xFF2E7D32),
      pending: pending ?? const Color(0xFFC62828),
      planned: planned ?? const Color(0xFF6A1B9A),
      today: today ?? const Color(0xFF1976D2),
      onStatus: Colors.white,
      surfaceToBuy: surfaceToBuy ?? surface ?? Colors.white,
      surfacePurchased: surfacePurchased ?? const Color(0xFFF2F8F3),
      border: border ?? const Color(0xFFE5E7EB),
      textSecondary: textSecondary ?? const Color(0xFF6B7280),
    );
  }

  /// Standard Dark Palette Foundation
  factory ShopTrackPalette.dark({
    required Color primary,
    Color? secondary,
    Color? purchased,
    Color? pending,
    Color? planned,
    Color? today,
  }) {
    return ShopTrackPalette(
      primary: primary,
      secondary: secondary ?? primary.withValues(alpha: 0.7),
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      error: const Color(0xFFCF6679),
      onPrimary: const Color(0xFF121212),
      onSecondary: const Color(0xFF121212),
      onBackground: const Color(0xFFE1E1E1),
      onSurface: const Color(0xFFE1E1E1),
      onError: const Color(0xFF121212),
      purchased: purchased ?? const Color(0xFF81C784),
      pending: pending ?? const Color(0xFFE57373),
      planned: planned ?? const Color(0xFFBA68C8),
      today: today ?? const Color(0xFF64B5F6),
      onStatus: const Color(0xFF121212),
      surfaceToBuy: const Color(0xFF1E1E1E),
      surfacePurchased: const Color(0xFF1B2A20),
      border: const Color(0xFF333333),
      textSecondary: const Color(0xFFB0B0B0),
    );
  }
}

/// Centralized Typography tokens.
class ShopTrackTypography {
  final TextStyle screenTitle;
  final TextStyle sectionTitle;
  final TextStyle itemName;
  final TextStyle itemSecondary;
  final TextStyle quantity;
  final TextStyle price;
  final TextStyle priceSmall;
  final TextStyle status;
  final TextStyle body;
  final TextStyle button;
  final TextStyle navLabel;

  const ShopTrackTypography({
    required this.screenTitle,
    required this.sectionTitle,
    required this.itemName,
    required this.itemSecondary,
    required this.quantity,
    required this.price,
    required this.priceSmall,
    required this.status,
    required this.body,
    required this.button,
    required this.navLabel,
  });

  factory ShopTrackTypography.standard(Color color) {
    return ShopTrackTypography(
      screenTitle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.5,
      ),
      sectionTitle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 0.2,
      ),
      itemName: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      itemSecondary: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color.withValues(alpha: 0.6),
      ),
      quantity: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      price: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      priceSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      status: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 1.0,
      ),
      body: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      button: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.5,
      ),
      navLabel: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}
