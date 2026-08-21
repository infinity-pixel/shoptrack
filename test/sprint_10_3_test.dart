import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';

void main() {
  group('Sprint 10.3: Future Session Splitting Logic', () {
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
      expect(session.plannedCount, 1); // Only pending item
    });

    test('plannedCount for past session counts all items', () {
      final now = DateTime.now();
      final pastDate = DateTime(now.year, now.month - 1, now.day);
      
      final session = ShoppingSession(
        id: 'past-1',
        date: pastDate,
        items: [
          const ShoppingItem(id: '1', name: 'A', isPurchased: false),
          const ShoppingItem(id: '2', name: 'B', isPurchased: true),
        ],
      );

      expect(session.isFuture, false);
      expect(session.plannedCount, 2); // All items
    });

    test('Mixed items identify correctly for splitting', () {
      final items = [
        const ShoppingItem(id: '1', name: 'A', isPurchased: false),
        const ShoppingItem(id: '2', name: 'B', isPurchased: true),
        const ShoppingItem(id: '3', name: 'C', isPurchased: true),
      ];
      
      final purchased = items.where((i) => i.isPurchased).toList();
      final pending = items.where((i) => !i.isPurchased).toList();
      
      expect(purchased.length, 2);
      expect(pending.length, 1);
    });
  });
}
