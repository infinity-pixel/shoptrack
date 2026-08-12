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
}
