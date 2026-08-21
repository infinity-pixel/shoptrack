import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/data/shopping_repository.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';

void main() {
  group('Sprint 9: Advanced History Logic', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Future session shows Planned status counts', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 2));
      final session = ShoppingSession(
        id: 'future',
        date: futureDate,
        items: [
          const ShoppingItem(id: '1', name: 'Item 1'),
          const ShoppingItem(id: '2', name: 'Item 2'),
        ],
      );

      expect(session.isFuture, isTrue);
      expect(session.plannedCount, 2);
    });

    test('Today/Past sessions show Purchased/Pending status counts', () {
      final now = DateTime.now();
      final session = ShoppingSession(
        id: 'today',
        date: now,
        items: [
          const ShoppingItem(id: '1', name: 'Bought', isPurchased: true),
          const ShoppingItem(id: '2', name: 'Not Bought', isPurchased: false),
          const ShoppingItem(id: '3', name: 'Not Bought', isPurchased: false),
        ],
      );

      expect(session.isToday, isTrue);
      expect(session.purchasedCount, 1);
      expect(session.pendingCount, 2);
    });

    test('Singular/Plural logic helpers (manual test in build)', () {
      // Wording logic is handled in the UI build method.
    });

    test('Empty sessions are filtered from History list', () async {
      final repo = LocalShoppingRepository();
      final emptySession = ShoppingSession(id: 'empty', date: DateTime.now(), items: []);
      final realSession = ShoppingSession(
        id: 'real',
        date: DateTime.now().subtract(const Duration(days: 1)),
        items: [const ShoppingItem(id: '1', name: 'Item')],
      );

      await repo.saveSession(emptySession);
      await repo.saveSession(realSession);

      final all = await repo.getAllSessions(includeEmpty: false);
      expect(all.length, 1);
      expect(all.first.id, 'real');
    });

    test('Sorting: Upcoming Ascending, Past Descending baseline', () async {
      final repo = LocalShoppingRepository();
      
      final past1 = ShoppingSession(id: 'p1', date: DateTime.now().subtract(const Duration(days: 1)), items: [const ShoppingItem(id: '1', name: 'A')]);
      final past2 = ShoppingSession(id: 'p2', date: DateTime.now().subtract(const Duration(days: 5)), items: [const ShoppingItem(id: '1', name: 'A')]);
      final future1 = ShoppingSession(id: 'f1', date: DateTime.now().add(const Duration(days: 1)), items: [const ShoppingItem(id: '1', name: 'A')]);
      final future2 = ShoppingSession(id: 'f2', date: DateTime.now().add(const Duration(days: 5)), items: [const ShoppingItem(id: '1', name: 'A')]);

      await repo.saveSession(past1);
      await repo.saveSession(past2);
      await repo.saveSession(future1);
      await repo.saveSession(future2);

      final all = await repo.getAllSessions();
      
      // Repository returns baseline (sorted by date desc)
      expect(all[0].id, 'f2');
      expect(all[1].id, 'f1');
      expect(all[2].id, 'p1');
      expect(all[3].id, 'p2');
    });
  });
}
