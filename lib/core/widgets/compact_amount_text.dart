import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../currency/currency_catalog.dart';
import '../utils/number_formatter.dart';

/// Shows a bounded shopping amount and exposes its full value on tap.
class CompactAmountText extends StatelessWidget {
  const CompactAmountText({
    super.key,
    required this.value,
    required this.currencyCode,
    required this.style,
    this.preference = NumberFormatPreference.automatic,
    this.includeCode = false,
    this.textAlign = TextAlign.end,
  });

  final double value;
  final String currencyCode;
  final TextStyle style;
  final NumberFormatPreference preference;
  final bool includeCode;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final locale = WidgetsBinding.instance.platformDispatcher.locale.toString();
    final full = NumberFormatter.formatPrice(
      value,
      currencyCode: currencyCode,
      includeCode: includeCode,
      preference: preference,
      deviceLocale: locale,
    );
    final display = NumberFormatter.formatDisplayPrice(
      value,
      currencyCode: currencyCode,
      includeCode: includeCode,
      preference: preference,
      deviceLocale: locale,
    );
    final symbol = CurrencyCatalog.resolve(currencyCode).symbol;
    final isArabicSymbol = RegExp(r'[\u0600-\u06ff]').hasMatch(symbol);
    return Tooltip(
      message: full,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        label: full,
        child: ExcludeSemantics(
          child: Text(
            display,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            textDirection: isArabicSymbol
                ? ui.TextDirection.rtl
                : ui.TextDirection.ltr,
            style: style,
          ),
        ),
      ),
    );
  }
}
