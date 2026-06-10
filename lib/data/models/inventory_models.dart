class InventoryCategory {
  final int id;
  final String name;
  final String? description;

  InventoryCategory({
    required this.id,
    required this.name,
    this.description,
  });

  factory InventoryCategory.fromJson(Map<String, dynamic> json) {
    return InventoryCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class InventoryItem {
  final int id;
  final String name;
  final int quantity;
  final int? inventoryTypeId;
  final InventoryCategory? inventoryType;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.inventoryTypeId,
    this.inventoryType,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      inventoryTypeId: json['inventory_type_id'],
      inventoryType: json['inventory_type'] != null
          ? InventoryCategory.fromJson(json['inventory_type'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'inventory_type_id': inventoryTypeId,
      'inventory_type': inventoryType?.toJson(),
    };
  }
}
