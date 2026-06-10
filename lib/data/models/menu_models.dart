class MenuItem {
  final int id;
  final String name;
  final String unitType;
  final String unitQuantity;
  final double price;
  final double? servingPrice;
  final double? deliveryPrice;
  final String costingStatus;
  final String status;

  MenuItem({
    required this.id,
    required this.name,
    required this.unitType,
    required this.unitQuantity,
    required this.price,
    this.servingPrice,
    this.deliveryPrice,
    required this.costingStatus,
    required this.status,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      unitType: json['unit_type'],
      unitQuantity: json['unit_quantity'],
      price: (json['price'] as num).toDouble(),
      servingPrice: json['serving_price'] != null ? (json['serving_price'] as num).toDouble() : null,
      deliveryPrice: json['delivery_price'] != null ? (json['delivery_price'] as num).toDouble() : null,
      costingStatus: json['costing_status'] ?? 'none',
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit_type': unitType,
      'unit_quantity': unitQuantity,
      'price': price,
      'serving_price': servingPrice,
      'delivery_price': deliveryPrice,
      'costing_status': costingStatus,
      'status': status,
    };
  }
}

class MenuCostingOverviewItem {
  final int menuItemId;
  final String menuItemName;
  final double currentMenuPrice;
  final int? costingId;
  final String costingStatus;
  final double? servingPrice;
  final double? deliveryPrice;
  final int stepsComplete;

  MenuCostingOverviewItem({
    required this.menuItemId,
    required this.menuItemName,
    required this.currentMenuPrice,
    this.costingId,
    required this.costingStatus,
    this.servingPrice,
    this.deliveryPrice,
    required this.stepsComplete,
  });

  factory MenuCostingOverviewItem.fromJson(Map<String, dynamic> json) {
    return MenuCostingOverviewItem(
      menuItemId: json['menu_item_id'],
      menuItemName: json['menu_item_name'],
      currentMenuPrice: (json['current_menu_price'] as num).toDouble(),
      costingId: json['costing_id'],
      costingStatus: json['costing_status'] ?? 'none',
      servingPrice: json['serving_price'] != null ? (json['serving_price'] as num).toDouble() : null,
      deliveryPrice: json['delivery_price'] != null ? (json['delivery_price'] as num).toDouble() : null,
      stepsComplete: json['steps_complete'] ?? 0,
    );
  }
}

class MenuVariant {
  final int id;
  final int menuItemId;
  final String variantName;
  final double servingPrice;
  final double deliveryPrice;
  final bool isActive;

  MenuVariant({
    required this.id,
    required this.menuItemId,
    required this.variantName,
    required this.servingPrice,
    required this.deliveryPrice,
    required this.isActive,
  });

  factory MenuVariant.fromJson(Map<String, dynamic> json) {
    return MenuVariant(
      id: json['id'],
      menuItemId: json['menu_item_id'],
      variantName: json['variant_name'],
      servingPrice: (json['serving_price'] as num).toDouble(),
      deliveryPrice: (json['delivery_price'] as num).toDouble(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_item_id': menuItemId,
      'variant_name': variantName,
      'serving_price': servingPrice,
      'delivery_price': deliveryPrice,
      'is_active': isActive,
    };
  }
}
