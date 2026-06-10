import 'package:flutter_test/flutter_test.dart';
import 'package:flamehouse_app/data/models/inventory_models.dart';
import 'package:flamehouse_app/data/models/menu_models.dart';
import 'package:flamehouse_app/data/models/costing_models.dart';

void main() {
  group('Inventory Models Parsing Tests', () {
    test('InventoryCategory parsing handles null description', () {
      final json = {
        'id': 1,
        'name': 'Breads',
        'description': null,
      };
      final category = InventoryCategory.fromJson(json);
      expect(category.id, 1);
      expect(category.name, 'Breads');
      expect(category.description, isNull);
    });

    test('InventoryItem parsing handles null category and integers as doubles', () {
      final json = {
        'id': 10,
        'name': 'Sugar',
        'quantity': 100,
        'inventory_type_id': null,
        'inventory_type': null,
      };
      final item = InventoryItem.fromJson(json);
      expect(item.id, 10);
      expect(item.name, 'Sugar');
      expect(item.quantity, 100);
      expect(item.inventoryTypeId, isNull);
      expect(item.inventoryType, isNull);
    });
  });

  group('Menu & Variant Models Parsing Tests', () {
    test('MenuItem parsing safely casts integer prices to double', () {
      final json = {
        'id': 5,
        'name': 'Butter Chicken',
        'unit_type': 'portion',
        'unit_quantity': '1',
        'price': 250, // integer from backend
        'serving_price': 240, // integer
        'delivery_price': null,
        'costing_status': 'complete',
        'status': 'active',
      };
      final item = MenuItem.fromJson(json);
      expect(item.price, 250.0);
      expect(item.servingPrice, 240.0);
      expect(item.deliveryPrice, isNull);
    });

    test('MenuVariant parsing handles active toggles and prices safely', () {
      final json = {
        'id': 20,
        'menu_item_id': 5,
        'variant_name': 'Half',
        'serving_price': 130.5,
        'delivery_price': 150,
        'is_active': false,
      };
      final variant = MenuVariant.fromJson(json);
      expect(variant.id, 20);
      expect(variant.menuItemId, 5);
      expect(variant.variantName, 'Half');
      expect(variant.servingPrice, 130.5);
      expect(variant.deliveryPrice, 150.0);
      expect(variant.isActive, isFalse);
    });
  });

  group('Costing Models Parsing Tests', () {
    test('MenuCosting parsing parses sub-lists and final margins defensively', () {
      final json = {
        'id': 100,
        'menu_item_id': 5,
        'status': 'draft',
        'serving_price': 180,
        'delivery_price': 210.5,
        'prep_items': [
          {'id': 1, 'description': 'Chicken', 'serving_cost': 50, 'delivery_cost': 50, 'notes': 'Fresh'},
        ],
        'overhead_items': [],
        'packing_items': null, // null list safety
        'final': {
          'id': 2,
          'profit_margin_pct': 30,
          'commission_pct': 15,
          'delivery_fee': 40,
          'other_description': null,
          'other_serving_cost': 0,
          'other_delivery_cost': 0,
        }
      };

      final costing = MenuCosting.fromJson(json);
      expect(costing.id, 100);
      expect(costing.prepItems.length, 1);
      expect(costing.prepItems.first.description, 'Chicken');
      expect(costing.prepItems.first.servingCost, 50.0);
      expect(costing.overheadItems, isEmpty);
      expect(costing.packingItems, isEmpty); // parsed safely from null
      expect(costing.finalCosting, isNotNull);
      expect(costing.finalCosting!.profitMarginPct, 30.0);
      expect(costing.finalCosting!.deliveryFee, 40.0);
    });
  });
}
