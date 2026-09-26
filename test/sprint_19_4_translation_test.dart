import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/currency/currency_catalog.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';

void main() {
  test('Arabic covers all Bangla interface keys', () {
    expect(shopTranslationKeys('ar'), shopTranslationKeys('bn'));
    for (final key in shopTranslationKeys('ar')) {
      expect(shopTrLanguage('ar', key), isNotEmpty, reason: key);
      final placeholders = RegExp(r'\{[^}]+\}');
      expect(
        placeholders
            .allMatches(shopTrLanguage('ar', key))
            .map((m) => m[0])
            .toSet(),
        placeholders.allMatches(key).map((m) => m[0]).toSet(),
        reason: key,
      );
    }
  });

  test(
    'Arabic digit shaping preserves signs, codes and all numeric digits',
    () {
      expect(shopDigitsLanguage('ar', 'BDT -1,234.50'), 'BDT -١,٢٣٤.٥٠');
      expect(shopDigitsLanguage('ar', '০১২৩৪৫৬৭৮৯'), '٠١٢٣٤٥٦٧٨٩');
      expect(shopDigitsLanguage('ar', '۰۱۲۳۴۵۶۷۸۹'), '٠١٢٣٤٥٦٧٨٩');
      expect(shopDigitsLanguage('en', 'BDT ১২৩'), 'BDT ১২৩');
      expect(shopNumberLanguage('ar', 2026).replaceAll(',', ''), '٢٠٢٦');
      expect(
        shopTrLanguage('ar', 'Cloud backup failed: API_CODE'),
        'تعذر النسخ الاحتياطي السحابي: API_CODE',
      );
      expect(shopTrLanguage('en', 'Calendar'), 'Calendar');
    },
  );

  test('Arabic and Bangla currency names cover the offered catalogue', () {
    for (final language in ['ar', 'bn']) {
      final missing = CurrencyCatalog.all.where(
        (currency) => shopTrLanguage(language, currency.name) == currency.name,
      );
      expect(
        missing,
        isEmpty,
        reason:
            'Untranslated currency names in $language: ${missing.map((c) => '${c.code}=${c.name}').join('; ')}',
      );
    }
  });

  testWidgets(
    'Arabic widgets translate interface but preserve user list names',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('en'), Locale('bn'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  const ShopText('My List'),
                  Text(shopListName(context, id: 'user-list', name: 'My List')),
                  Text(shopNumber(context, 19)),
                  Text(shopIsArabic(context) ? 'rtl-ready' : 'unexpected'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('قائمتي'), findsOneWidget);
      expect(find.text('My List'), findsOneWidget);
      expect(find.text('١٩'), findsOneWidget);
      expect(find.text('rtl-ready'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
