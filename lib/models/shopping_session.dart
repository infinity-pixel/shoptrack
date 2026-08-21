import 'shopping_item.dart';

class ShoppingSession {
  final String id;
  final DateTime date;
  final List<ShoppingItem> items;

  const ShoppingSession({
    required this.id,
    required this.date,
    required this.items,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
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

  double get totalPurchasedAmount =>
      items.where((i) => i.isPurchased).fold(0.0, (sum, item) => sum + item.pricing.totalPrice);

  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + item.pricing.totalPrice);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory ShoppingSession.fromJson(Map<String, dynamic> json) {
    return ShoppingSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List<dynamic>)
          .map((itemJson) => ShoppingItem.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
    );
  }

  ShoppingSession copyWith({
    String? id,
    DateTime? date,
    List<ShoppingItem>? items,
  }) {
    return ShoppingSession(
      id: id ?? this.id,
      date: date ?? this.date,
      items: items ?? this.items,
    );
  }
}
