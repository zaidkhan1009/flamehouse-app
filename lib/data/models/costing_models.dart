class CostingPrepItem {
  final int? id;
  final String description;
  final double servingCost;
  final double deliveryCost;
  final String? notes;

  CostingPrepItem({
    this.id,
    required this.description,
    required this.servingCost,
    required this.deliveryCost,
    this.notes,
  });

  factory CostingPrepItem.fromJson(Map<String, dynamic> json) {
    return CostingPrepItem(
      id: json['id'],
      description: json['description'],
      servingCost: (json['serving_cost'] as num).toDouble(),
      deliveryCost: (json['delivery_cost'] as num).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'serving_cost': servingCost,
      'delivery_cost': deliveryCost,
      if (notes != null) 'notes': notes,
    };
  }
}

class CostingOverheadItem {
  final int? id;
  final String costType;
  final String? description;
  final double servingCost;
  final double deliveryCost;

  CostingOverheadItem({
    this.id,
    required this.costType,
    this.description,
    required this.servingCost,
    required this.deliveryCost,
  });

  factory CostingOverheadItem.fromJson(Map<String, dynamic> json) {
    return CostingOverheadItem(
      id: json['id'],
      costType: json['cost_type'],
      description: json['description'],
      servingCost: (json['serving_cost'] as num).toDouble(),
      deliveryCost: (json['delivery_cost'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cost_type': costType,
      if (description != null) 'description': description,
      'serving_cost': servingCost,
      'delivery_cost': deliveryCost,
    };
  }
}

class CostingPackingItem {
  final int? id;
  final String description;
  final double servingCost;
  final double deliveryCost;

  CostingPackingItem({
    this.id,
    required this.description,
    required this.servingCost,
    required this.deliveryCost,
  });

  factory CostingPackingItem.fromJson(Map<String, dynamic> json) {
    return CostingPackingItem(
      id: json['id'],
      description: json['description'],
      servingCost: (json['serving_cost'] as num).toDouble(),
      deliveryCost: (json['delivery_cost'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'serving_cost': servingCost,
      'delivery_cost': deliveryCost,
    };
  }
}

class CostingFinal {
  final int? id;
  final double profitMarginPct;
  final double commissionPct;
  final double deliveryFee;
  final String? otherDescription;
  final double otherServingCost;
  final double otherDeliveryCost;

  CostingFinal({
    this.id,
    required this.profitMarginPct,
    required this.commissionPct,
    required this.deliveryFee,
    this.otherDescription,
    required this.otherServingCost,
    required this.otherDeliveryCost,
  });

  factory CostingFinal.fromJson(Map<String, dynamic> json) {
    return CostingFinal(
      id: json['id'],
      profitMarginPct: (json['profit_margin_pct'] as num).toDouble(),
      commissionPct: (json['commission_pct'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      otherDescription: json['other_description'],
      otherServingCost: (json['other_serving_cost'] as num).toDouble(),
      otherDeliveryCost: (json['other_delivery_cost'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profit_margin_pct': profitMarginPct,
      'commission_pct': commissionPct,
      'delivery_fee': deliveryFee,
      if (otherDescription != null) 'other_description': otherDescription,
      'other_serving_cost': otherServingCost,
      'other_delivery_cost': otherDeliveryCost,
    };
  }
}

class MenuCosting {
  final int id;
  final int menuItemId;
  final String status;
  final double? servingPrice;
  final double? deliveryPrice;
  final List<CostingPrepItem> prepItems;
  final List<CostingOverheadItem> overheadItems;
  final List<CostingPackingItem> packingItems;
  final CostingFinal? finalCosting;

  MenuCosting({
    required this.id,
    required this.menuItemId,
    required this.status,
    this.servingPrice,
    this.deliveryPrice,
    required this.prepItems,
    required this.overheadItems,
    required this.packingItems,
    this.finalCosting,
  });

  factory MenuCosting.fromJson(Map<String, dynamic> json) {
    return MenuCosting(
      id: json['id'],
      menuItemId: json['menu_item_id'],
      status: json['status'],
      servingPrice: json['serving_price'] != null ? (json['serving_price'] as num).toDouble() : null,
      deliveryPrice: json['delivery_price'] != null ? (json['delivery_price'] as num).toDouble() : null,
      prepItems: (json['prep_items'] as List? ?? [])
          .map((item) => CostingPrepItem.fromJson(item))
          .toList(),
      overheadItems: (json['overhead_items'] as List? ?? [])
          .map((item) => CostingOverheadItem.fromJson(item))
          .toList(),
      packingItems: (json['packing_items'] as List? ?? [])
          .map((item) => CostingPackingItem.fromJson(item))
          .toList(),
      finalCosting: json['final'] != null ? CostingFinal.fromJson(json['final']) : null,
    );
  }
}
