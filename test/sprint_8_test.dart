import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/data/shopping_repository.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';

void main() {
  group('Sprint 8: Session Architecture', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ShoppingSession handles items and date', () {
      final date = DateTime(2026, 8, 19);
      final item = const ShoppingItem(id: '1', name: 'Milk');
      final session = ShoppingSession(id: 's1', date: date, items: [item]);

      expect(session.id, 's1');
      expect(session.date, date);
      expect(session.items.length, 1);
      expect(session.items.first.name, 'Milk');
    });

    test('isToday returns true only for current date', () {
      final now = DateTime.now();
      final todaySession = ShoppingSession(
        id: 'today',
        date: DateTime(now.year, now.month, now.day),
        items: [],
      );
      final oldSession = ShoppingSession(
        id: 'yesterday',
        date: now.subtract(const Duration(days: 1)),
        items: [],
      );

      expect(todaySession.isToday, isTrue);
      expect(oldSession.isToday, isFalse);
    });

    test('Serialization preserves everything', () {
      final date = DateTime(2026, 8, 19);
      final item = const ShoppingItem(
        id: '1',
        name: 'Milk',
        quantityValue: 2,
        shoppingUnit: ShoppingUnit.l,
        isPurchased: true,
      );
      final session = ShoppingSession(id: 's1', date: date, items: [item]);

      final json = session.toJson();
      final reconstructed = ShoppingSession.fromJson(json);

      expect(reconstructed.id, session.id);
      expect(reconstructed.date, session.date);
      expect(reconstructed.items.length, 1);
      expect(reconstructed.items.first.name, 'Milk');
      expect(reconstructed.items.first.isPurchased, isTrue);
      expect(reconstructed.items.first.quantityValue, 2.0);
    });
  });

  group('Sprint 8: Repository Multi-Session Logic', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads empty session for new date', () async {
      final repo = LocalShoppingRepository();
      final date = DateTime(2026, 8, 20);
      final session = await repo.getSessionByDate(date);
      
      expect(session.items, isEmpty);
      expect(session.date, date);
    });

    test('Persistence isolates separate dates', () async {
      final repo = LocalShoppingRepository();
      
      final date1 = DateTime(2026, 8, 19);
      final s1 = ShoppingSession(id: '1', date: date1, items: [
        const ShoppingItem(id: 'i1', name: 'Item 1')
      ]);
      
      final date2 = DateTime(2026, 8, 20);
      final s2 = ShoppingSession(id: '2', date: date2, items: [
        const ShoppingItem(id: 'i2', name: 'Item 2')
      ]);

      await repo.saveSession(s1);
      await repo.saveSession(s2);

      final loadedS1 = await repo.getSessionByDate(date1);
      final loadedS2 = await repo.getSessionByDate(date2);

      expect(loadedS1.items.first.name, 'Item 1');
      expect(loadedS2.items.first.name, 'Item 2');
      expect(loadedS1.items.length, 1);
      expect(loadedS2.items.length, 1);
    });

    test('getAllSessions sorts by date newest first', () async {
      final repo = LocalShoppingRepository();
      
      final sOld = ShoppingSession(id: 'old', date: DateTime(2026, 8, 1), items: []);
      final sNew = ShoppingSession(id: 'new', date: DateTime(2026, 8, 20), items: []);

      await repo.saveSession(sOld);
      await repo.saveSession(sNew);

      final all = await repo.getAllSessions();
      expect(all.first.id, 'new');
      expect(all.last.id, 'old');
    });

    test('Migration from Sprint 7 data works', () async {
      SharedPreferences.setMockInitialValues({
        'shopping_items': '[{"id": "legacy", "name": "Old Item", "isPurchased": false, "position": 0, "pricingMode": "total"}]'
      });
      
      final repo = LocalShoppingRepository();
      final all = await repo.getAllSessions();
      
      expect(all.length, 1);
      expect(all.first.items.first.name, 'Old Item');
      
      // Check if old key is cleared
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('shopping_items'), isFalse);
    });
  });
}
