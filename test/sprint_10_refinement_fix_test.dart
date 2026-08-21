import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';

void main() {
  group('Sprint 10 Refinement: Future Session Logic & Planned Count', () {
    test('plannedCount for future session counts only pending items', () {
      final now = DateTime.now();
      final futureDate = DateTime(now.year, now.month + 1, now.day);
      
      final session = ShoppingSession(
        id: 'future-1',
        date: futureDate,
        items: [
          const ShoppingItem(id: '1', name: 'A', isPurchased: false),
          const ShoppingItem(id: '2', name: 'B', isPurchased: true),
        ],
      );

      expect(session.isFuture, true);
      expect(session.pendingCount, 1);
      expect(session.purchasedCount, 1);
      // Requirement: Future session planned count must count only actual unpurchased items
      expect(session.plannedCount, 1);
    });

    test('plannedCount for past/today session counts all items', () {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      
      final session = ShoppingSession(
        id: 'today-1',
        date: todayDate,
        items: [
          const ShoppingItem(id: '1', name: 'A', isPurchased: false),
          const ShoppingItem(id: '2', name: 'B', isPurchased: true),
        ],
      );

      expect(session.isFuture, false);
      expect(session.plannedCount, 2);
    });

    test('Splitting logic correctly identifies purchased items', () {
      final item1 = const ShoppingItem(id: '1', name: 'A', isPurchased: false);
      final item2 = const ShoppingItem(id: '2', name: 'B', isPurchased: true);
      final session = ShoppingSession(
        id: 's1',
        date: DateTime(2026, 8, 10),
        items: [item1, item2],
      );

      final purchased = session.items.where((i) => i.isPurchased).toList();
      final pending = session.items.where((i) => !i.isPurchased).toList();

      expect(purchased.length, 1);
      expect(purchased[0].id, '2');
      expect(pending.length, 1);
      expect(pending[0].id, '1');
    });
  });
}
