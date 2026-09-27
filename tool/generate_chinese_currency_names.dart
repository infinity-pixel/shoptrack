// Run from the repository root after downloading Unicode CLDR's
// cldr-numbers-full/main/zh/currencies.json to build/cldr_zh_currencies.json.
import 'dart:convert';
import 'dart:io';

import 'package:shoptrack/core/currency/currency_catalog.dart';

void main() {
  final source = jsonDecode(
    File('build/cldr_zh_currencies.json').readAsStringSync(),
  );
  final currencies = source['main']['zh']['numbers']['currencies'] as Map;
  final names = <String, String>{};
  for (final currency in CurrencyCatalog.all) {
    final translated = currencies[currency.code]?['displayName'] as String?;
    if (translated == null) {
      throw StateError('Missing CLDR name: ${currency.code}');
    }
    names[currency.name] = translated;
  }
  String quote(String value) =>
      "'${value.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll(r'$', r'\$')}'";
  final output = StringBuffer(
    '''// Generated from Unicode CLDR zh currency display names, 2026-09-27.
// Source: https://github.com/unicode-org/cldr-json/tree/main/cldr-json/cldr-numbers-full/main/zh
// Unicode License V3: see shopCurrencyDataLicense in shoptrack_currency_names.dart.
// Regenerate with tool/generate_chinese_currency_names.dart.
const shopChineseCurrencyNames = <String, String>{
''',
  );
  for (final entry in names.entries) {
    output.writeln('  ${quote(entry.key)}: ${quote(entry.value)},');
  }
  output.writeln('};');
  File(
    'lib/core/localization/shoptrack_chinese_currency_names.dart',
  ).writeAsStringSync(output.toString());
}
