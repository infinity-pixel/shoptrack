import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/currency/currency_catalog.dart';
import 'package:shoptrack/core/currency/currency_totals.dart';
import 'package:shoptrack/core/data/session_merge.dart';
import 'package:shoptrack/core/data/settings_repository.dart';
import 'package:shoptrack/core/utils/number_formatter.dart';
import 'package:shoptrack/core/utils/shopping_list_text_formatter.dart';
import 'package:shoptrack/models/app_backup.dart';
import 'package:shoptrack/models/app_settings.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 19 currency catalogue', () {
    test('offers current payment currencies without non-cash ISO units', () {
      expect(CurrencyCatalog.all.length, greaterThan(140));
      for (final code in ['BDT', 'USD', 'EUR', 'JPY', 'XAF', 'XOF']) {
        expect(CurrencyCatalog.find(code), isNotNull, reason: code);
      }
      for (final code in ['BTC', 'BGN', 'XAU', 'XDR', 'XTS', 'XXX']) {
        expect(CurrencyCatalog.find(code), isNull, reason: code);
      }
      expect(CurrencyCatalog.find('BDT')!.symbol, '৳');
      expect(CurrencyCatalog.find('BHD')!.decimalDigits, 3);
    });

    test(
      'orders default then unique recent currencies before the catalogue',
      () {
        final values = CurrencyCatalog.prioritized(
          defaultCurrencyCode: 'BDT',
          recentCurrencyCodes: const ['USD', 'EUR', 'USD', 'BAD'],
        );
        expect(values.take(3).map((value) => value.code), [
          'BDT',
          'USD',
          'EUR',
        ]);
        expect(values.map((value) => value.code).toSet().length, values.length);
        expect(CurrencyCatalog.search('bangladesh').single.code, 'BDT');
      },
    );
  });

  group('Sprint 19 item migration and persistence', () {
    test('new backups use the currency-aware schema version', () {
      expect(AppBackup.currentVersion, 2);
    });

    test('round-trips item currency and migrates legacy items to BDT', () {
      const item = ShoppingItem(
        id: 'usd',
        name: 'Coffee',
        priceValue: 4.5,
        currencyCode: 'USD',
      );
      expect(ShoppingItem.fromJson(item.toJson()).currencyCode, 'USD');

      final legacy = Map<String, dynamic>.from(item.toJson())
        ..remove('currencyCode');
      expect(ShoppingItem.fromJson(legacy).currencyCode, 'BDT');

      final future = Map<String, dynamic>.from(item.toJson())
        ..['currencyCode'] = 'abc';
      expect(ShoppingItem.fromJson(future).currencyCode, 'ABC');

      final malformed = Map<String, dynamic>.from(item.toJson())
        ..['currencyCode'] = 'not-a-code';
      expect(ShoppingItem.fromJson(malformed).currencyCode, 'BDT');
    });

    test('backup round-trip retains per-item currency and recent choices', () {
      final backup = AppBackup(
        backupVersion: AppBackup.currentVersion,
        appVersion: 'test',
        timestamp: DateTime(2026, 9, 19),
        sessions: [
          ShoppingSession(
            id: 'day',
            date: DateTime(2026, 9, 19),
            items: const [
              ShoppingItem(
                id: 'eur',
                name: 'Bread',
                priceValue: 2,
                currencyCode: 'EUR',
              ),
            ],
          ),
        ],
        settings: const AppSettings(
          currency: 'BDT',
          recentCurrencies: ['EUR', 'USD'],
        ),
      );
      final restored = AppBackup.fromJson(backup.toJson());
      expect(restored.sessions.single.items.single.currencyCode, 'EUR');
      expect(restored.settings.recentCurrencies, ['EUR', 'USD']);
    });
  });

  group('Sprint 19 settings behavior', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('sanitizes recent currencies and never treats recent as default', () {
      final settings = AppSettings.fromJson({
        'currency': 'usd',
        'recentCurrencies': ['USD', 'EUR', 'EUR', 'BTC', 'BDT'],
      });
      expect(settings.currency, 'USD');
      expect(settings.recentCurrencies, ['EUR', 'BDT']);

      final used = settings.recordRecentCurrency('JPY');
      expect(used.currency, 'USD');
      expect(used.recentCurrencies, ['JPY', 'EUR', 'BDT']);
    });

    test(
      'changing default keeps historical choices but not the new default',
      () async {
        final repository = LocalSettingsRepository();
        final service = SettingsService(repository);
        await service.loadSettings();
        await service.recordRecentCurrency('USD');
        await service.recordRecentCurrency('EUR');
        await service.updateCurrency('USD');

        expect(service.settings.currency, 'USD');
        expect(service.settings.recentCurrencies, ['EUR']);
        expect((await repository.getSettings()).currency, 'USD');
      },
    );
  });

  group('Sprint 19 fixed-precision grouped totals', () {
    const bdt = ShoppingItem(
      id: 'bdt',
      name: 'Rice',
      priceValue: 100,
      currencyCode: 'BDT',
    );
    const usdA = ShoppingItem(
      id: 'usd-a',
      name: 'Coffee',
      priceValue: 0.1,
      currencyCode: 'USD',
    );
    const usdB = ShoppingItem(
      id: 'usd-b',
      name: 'Milk',
      priceValue: 0.2,
      currencyCode: 'USD',
      isPurchased: true,
    );

    test('keeps currencies separate and rounds through minor units', () {
      final totals = CurrencyTotals.fromItems([bdt, usdA, usdB]);
      expect(totals.length, 2);
      expect(totals['BDT']!.value, 100);
      expect(totals['USD']!.minorUnits, BigInt.from(30));
      expect(totals['USD']!.value, 0.3);
    });

    test('session exposes total, pending and purchased currency groups', () {
      final session = ShoppingSession(
        id: 'mixed',
        date: DateTime(2026, 9, 19),
        items: const [bdt, usdA, usdB],
      );
      expect(session.totalsByCurrency.length, 2);
      expect(session.pendingTotalsByCurrency['BDT']!.value, 100);
      expect(session.pendingTotalsByCurrency['USD']!.value, 0.1);
      expect(session.purchasedTotalsByCurrency['USD']!.value, 0.2);
      expect(() => session.totalAmount, throwsStateError);
    });
  });

  group('Sprint 19 formatting and sharing', () {
    test('keeps legacy BDT output and supports currency precision', () {
      expect(NumberFormatter.formatPrice(12500), '৳12,500');
      final bhd = NumberFormatter.formatPrice(
        12.345,
        currencyCode: 'BHD',
        includeCode: true,
      );
      expect(bhd, contains('BHD'));
      expect(bhd, endsWith('12.345'));
      expect(NumberFormatter.formatPrice(4, currencyCode: 'ABC'), 'ABC 4');
    });

    test('plain-text export labels items and totals without conversion', () {
      final session = ShoppingSession(
        id: 'share',
        date: DateTime(2026, 9, 19),
        items: const [
          ShoppingItem(
            id: 'rice',
            name: 'Rice',
            priceValue: 100,
            currencyCode: 'BDT',
          ),
          ShoppingItem(
            id: 'coffee',
            name: 'Coffee',
            priceValue: 5,
            currencyCode: 'USD',
            isPurchased: true,
          ),
        ],
      );
      final text = ShoppingListTextFormatter.format(session);
      expect(text, contains('☐ Rice — BDT ৳100'));
      expect(text, contains(r'☑ Coffee — USD $5'));
      expect(text, contains('Pending totals:\n  BDT ৳100'));
      expect(text, contains('Purchased totals:\n  USD \$5'));
      expect(text, isNot(contains('৳105')));
    });

    test('empty status total uses the scoped list currency', () {
      final text = ShoppingListTextFormatter.format(
        ShoppingSession(
          id: 'usd-only',
          date: DateTime(2026, 9, 19),
          items: const [
            ShoppingItem(
              id: 'coffee',
              name: 'Coffee',
              priceValue: 5,
              currencyCode: 'USD',
              isPurchased: true,
            ),
          ],
        ),
      );
      expect(text, contains(r'Pending total: $0'));
      expect(text, contains(r'Purchased total: $5'));
      expect(text, isNot(contains('Pending total: ৳0')));
    });
  });

  test('currency is part of the atomic sync pricing group', () {
    ShoppingSession session(ShoppingItem item) => ShoppingSession(
      id: 'merge',
      date: DateTime(2026, 9, 19),
      items: [item],
    );

    const base = ShoppingItem(id: 'item', name: 'Coffee', priceValue: 10);
    final conflict = SessionMerge(
      session(base).toJson(),
      session(base.copyWith(currencyCode: 'USD')).toJson(),
      session(base.copyWith(priceValue: 20)).toJson(),
    );
    expect(conflict.conflicts, contains('Coffee: quantity / price'));

    final independent = SessionMerge(
      session(base).toJson(),
      session(base.copyWith(currencyCode: 'USD')).toJson(),
      session(base.copyWith(name: 'Fresh Coffee')).toJson(),
    );
    expect(independent.conflicts, isEmpty);
    final item = ShoppingSession.fromJson(independent.value!).items.single;
    expect(item.currencyCode, 'USD');
    expect(item.name, 'Fresh Coffee');
  });
}
