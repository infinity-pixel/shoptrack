class ShoppingItem {
  final String name;
  final String? quantity;
  final String? unit;
  final String? price;
  final String? notes;
  final bool isPurchased;

  const ShoppingItem({
    required this.name,
    this.quantity,
    this.unit,
    this.price,
    this.notes,
    this.isPurchased = false,
  });

  ShoppingItem copyWith({
    String? name,
    String? quantity,
    String? unit,
    String? price,
    String? notes,
    bool? isPurchased,
  }) {
    return ShoppingItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}
