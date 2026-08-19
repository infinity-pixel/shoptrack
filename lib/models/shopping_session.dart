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
