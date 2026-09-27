import 'package:flutter/material.dart';

/// Stable Latin digits/currency signs, with glyph-only fallbacks for signs that
/// are missing from older device fonts. Keep receipt totals in LibreBaskerville.
const shopCurrencyFontFallbacks = [
  'ShopTrackTaka',
  'ShopTrackCurrency',
  'ShopTrackRufiyaa',
];

TextStyle shopAmountStyle(TextStyle style, {String? fontFamily}) =>
    style.copyWith(
      fontFamily: fontFamily ?? 'ShopTrackAmounts',
      fontFamilyFallback: [
        ...shopCurrencyFontFallbacks,
        // Keep the interface's script font available for Arabic-Indic digits
        // and localized unit suffixes, without letting it replace Latin money.
        if (style.fontFamily != null) style.fontFamily!,
        ...?style.fontFamilyFallback,
      ],
    );
