import 'shopping_item.dart';
import 'shopping_list_group.dart';

class ShoppingSession {
  final String id;
  final DateTime date;
  final List<ShoppingItem> items;
  final List<ShoppingListGroup> lists;

  const ShoppingSession({
    required this.id,
    required this.date,
    required this.items,
    this.lists = const [ShoppingListGroup.defaultList],
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAfter(today);
  }

  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
  }

  int get purchasedCount => items.where((i) => i.isPurchased).length;
  int get pendingCount => items.where((i) => !i.isPurchased).length;
  int get plannedCount => isFuture ? pendingCount : items.length;

  double get totalPurchasedAmount => items
      .where((i) => i.isPurchased)
      .fold(0.0, (sum, item) => sum + item.pricing.totalPrice);

  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + item.pricing.totalPrice);

  List<ShoppingListGroup> get orderedLists {
    final result = lists.isEmpty
        ? <ShoppingListGroup>[ShoppingListGroup.defaultList]
        : List<ShoppingListGroup>.from(lists);
    result.sort((a, b) => a.position.compareTo(b.position));
    return result;
  }

  List<ShoppingItem> itemsForList(String listId) {
    return items.where((item) {
      final effectiveListId = item.listId ?? ShoppingListGroup.defaultId;
      return effectiveListId == listId;
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'lists': lists.map((list) => list.toJson()).toList(),
    };
  }

  factory ShoppingSession.fromJson(Map<String, dynamic> json) {
    return ShoppingSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List<dynamic>)
          .map(
            (itemJson) =>
                ShoppingItem.fromJson(itemJson as Map<String, dynamic>),
          )
          .toList(),
      lists: json['lists'] == null
          ? const [ShoppingListGroup.defaultList]
          : (json['lists'] as List<dynamic>)
                .map(
                  (listJson) => ShoppingListGroup.fromJson(
                    listJson as Map<String, dynamic>,
                  ),
                )
                .toList(),
    );
  }

  ShoppingSession copyWith({
    String? id,
    DateTime? date,
    List<ShoppingItem>? items,
    List<ShoppingListGroup>? lists,
  }) {
    return ShoppingSession(
      id: id ?? this.id,
      date: date ?? this.date,
      items: items ?? this.items,
      lists: lists ?? this.lists,
    );
  }
}
