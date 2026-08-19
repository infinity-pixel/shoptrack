import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/models/shopping_item.dart';

void main() {
  group('Sprint 7: Edit and Delete logic', () {
    test('Editing an item preserves its original identity', () {
      const original = ShoppingItem(
        id: 'id-1',
        name: 'Milk',
        position: 1,
        isPurchased: false,
      );

      final edited = original.copyWith(name: 'Almond Milk');

      expect(edited.id, 'id-1');
      expect(edited.position, 1);
      expect(edited.isPurchased, false);
      expect(edited.name, 'Almond Milk');
    });

    test('Deletion logic in memory', () {
      final items = [
        const ShoppingItem(id: '1', name: 'A'),
        const ShoppingItem(id: '2', name: 'B'),
        const ShoppingItem(id: '3', name: 'C'),
      ];

      items.removeWhere((item) => item.id == '2');
      expect(items.length, 2);
      expect(items.any((item) => item.id == '2'), isFalse);
    });

    test('Undo logic: restoring item properties', () {
      final items = <ShoppingItem>[];
      const deletedItem = ShoppingItem(
        id: 'id-undo',
        name: 'Milk',
        position: 2,
        isPurchased: true,
      );

      // Simulation of Undo
      items.add(deletedItem);

      expect(items.first.id, 'id-undo');
      expect(items.first.position, 2);
      expect(items.first.isPurchased, isTrue);
    });
  });
}
