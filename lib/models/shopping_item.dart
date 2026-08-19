import '../core/utils/pricing_calculator.dart';

enum PricingMode {
  total,
  unit,
}

enum ShoppingUnit {
  kg,
  g,
  l,
  ml,
  pcs,
  packet,
  package;

  String get displayName {
    switch (this) {
      case ShoppingUnit.kg:
        return 'Kilogram (kg)';
      case ShoppingUnit.g:
        return 'Gram (g)';
      case ShoppingUnit.l:
        return 'Litre (L)';
      case ShoppingUnit.ml:
        return 'Millilitre (mL)';
      case ShoppingUnit.pcs:
        return 'Piece (pc)';
      case ShoppingUnit.packet:
        return 'Packet';
      case ShoppingUnit.package:
        return 'Package';
    }
  }

  String get symbol {
    switch (this) {
      case ShoppingUnit.kg:
        return 'kg';
      case ShoppingUnit.g:
        return 'g';
      case ShoppingUnit.l:
        return 'L';
      case ShoppingUnit.ml:
        return 'mL';
      case ShoppingUnit.pcs:
        return 'pc';
      case ShoppingUnit.packet:
        return 'packet';
      case ShoppingUnit.package:
        return 'package';
    }
  }

  bool get isMass => this == ShoppingUnit.kg || this == ShoppingUnit.g;
  bool get isVolume => this == ShoppingUnit.l || this == ShoppingUnit.ml;

  bool isCompatibleWith(ShoppingUnit other) {
    if (this == other) return true;
    if (isMass && other.isMass) return true;
    if (isVolume && other.isVolume) return true;
    return false;
  }

  ShoppingUnit get standardBasis {
    if (isMass) return ShoppingUnit.kg;
    if (isVolume) return ShoppingUnit.l;
    return this;
  }
}

class ShoppingItem {
  final String id;
  final String name;
  final String? quantity; // Kept for UI compatibility if needed
  final String? unit; // Kept for UI compatibility if needed
  final String? price; // Kept for UI compatibility if needed
  final String? notes;
  final bool isPurchased;

  // New Pricing System Fields
  final double? quantityValue;
  final double? priceValue;
  final PricingMode pricingMode;
  final ShoppingUnit? shoppingUnit;
  final ShoppingUnit? priceBasis;

  // Reordering
  final int position;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.price,
    this.notes,
    this.isPurchased = false,
    this.quantityValue,
    this.priceValue,
    this.pricingMode = PricingMode.total,
    this.shoppingUnit,
    this.priceBasis,
    this.position = 0,
  });

  PricingResult get pricing {
    return PricingCalculator.calculate(
      quantity: quantityValue,
      priceValue: priceValue,
      mode: pricingMode,
      unit: shoppingUnit,
      priceBasis: priceBasis,
    );
  }

  String get unitLabel => shoppingUnit?.symbol ?? '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'notes': notes,
      'isPurchased': isPurchased,
      'quantityValue': quantityValue,
      'priceValue': priceValue,
      'pricingMode': pricingMode.name,
      'shoppingUnit': shoppingUnit?.name,
      'priceBasis': priceBasis?.name,
      'position': position,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String?,
      unit: json['unit'] as String?,
      price: json['price'] as String?,
      notes: json['notes'] as String?,
      isPurchased: json['isPurchased'] as bool? ?? false,
      quantityValue: (json['quantityValue'] as num?)?.toDouble(),
      priceValue: (json['priceValue'] as num?)?.toDouble(),
      pricingMode: PricingMode.values.firstWhere(
        (e) => e.name == json['pricingMode'],
        orElse: () => PricingMode.total,
      ),
      shoppingUnit: json['shoppingUnit'] != null
          ? ShoppingUnit.values.firstWhere(
              (e) => e.name == json['shoppingUnit'],
            )
          : null,
      priceBasis: json['priceBasis'] != null
          ? ShoppingUnit.values.firstWhere(
              (e) => e.name == json['priceBasis'],
            )
          : null,
      position: json['position'] as int? ?? 0,
    );
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? quantity,
    String? unit,
    String? price,
    String? notes,
    bool? isPurchased,
    double? quantityValue,
    double? priceValue,
    PricingMode? pricingMode,
    ShoppingUnit? shoppingUnit,
    ShoppingUnit? priceBasis,
    int? position,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      isPurchased: isPurchased ?? this.isPurchased,
      quantityValue: quantityValue ?? this.quantityValue,
      priceValue: priceValue ?? this.priceValue,
      pricingMode: pricingMode ?? this.pricingMode,
      shoppingUnit: shoppingUnit ?? this.shoppingUnit,
      priceBasis: priceBasis ?? this.priceBasis,
      position: position ?? this.position,
    );
  }
}
