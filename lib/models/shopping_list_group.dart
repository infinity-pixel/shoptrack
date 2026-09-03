class ShoppingListGroup {
  static const String defaultId = 'default-list';
  static const ShoppingListGroup defaultList = ShoppingListGroup(
    id: defaultId,
    name: 'My List',
    position: 0,
  );

  final String id;
  final String name;
  final int position;

  const ShoppingListGroup({
    required this.id,
    required this.name,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'position': position,
  };

  factory ShoppingListGroup.fromJson(Map<String, dynamic> json) {
    return ShoppingListGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      position: json['position'] as int? ?? 0,
    );
  }

  ShoppingListGroup copyWith({String? id, String? name, int? position}) {
    return ShoppingListGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
    );
  }
}
