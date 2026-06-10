import 'package:flutter_test/flutter_test.dart';
import 'package:flamehouse_app/data/models/menu_models.dart';
import 'package:flamehouse_app/data/models/inventory_models.dart';

// Validator functions extracted for isolated unit testing
String? validateUnitQuantity(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Enter unit qty';
  }
  final trimVal = value.trim();
  final number = double.tryParse(trimVal);
  if (number != null) {
    if (number <= 0) return 'Must be positive';
    return null;
  }
  final parts = trimVal.split('/');
  if (parts.length == 2) {
    final n1 = double.tryParse(parts[0].trim());
    final n2 = double.tryParse(parts[1].trim());
    if (n1 != null && n2 != null && n1 > 0 && n2 > 0) {
      return null;
    }
  }
  return 'Enter positive number or fraction (e.g. 1.5, 1/2)';
}

String? validatePrice(String? value) {
  if (value == null || value.trim().isEmpty) return 'Enter a price';
  final parsed = double.tryParse(value.trim());
  if (parsed == null) return 'Enter valid price';
  if (parsed < 0) return 'Price cannot be negative';
  return null;
}

// KPI Calculation logic helper
Map<String, dynamic> calculateDashboardMetrics({
  required List<MenuItem> menuItems,
  required List<InventoryItem> inventoryItems,
  required int lowStockThreshold,
}) {
  final activeMenuCount = menuItems.where((item) => item.status == 'active').length;
  final outOfStockCount = inventoryItems.where((item) => item.quantity == 0).length;
  final lowStockCount = inventoryItems.where((item) => item.quantity > 0 && item.quantity <= lowStockThreshold).length;
  
  final costingApprovedCount = menuItems.where((item) => item.costingStatus == 'approved').length;
  final double costingCoverage = menuItems.isEmpty 
      ? 0.0 
      : (costingApprovedCount / menuItems.length) * 100;

  return {
    'activeMenuCount': activeMenuCount,
    'outOfStockCount': outOfStockCount,
    'lowStockCount': lowStockCount,
    'costingCoverage': costingCoverage,
  };
}

void main() {
  group('Unit Quantity Validation Tests', () {
    test('Valid integer and decimals return null', () {
      expect(validateUnitQuantity('1'), isNull);
      expect(validateUnitQuantity('2.5'), isNull);
      expect(validateUnitQuantity(' 500 '), isNull);
    });

    test('Valid fractions (e.g. 1/2, 3/4) return null', () {
      expect(validateUnitQuantity('1/2'), isNull);
      expect(validateUnitQuantity('3/4'), isNull);
      expect(validateUnitQuantity(' 1 / 4 '), isNull);
    });

    test('Empty or blank values return error', () {
      expect(validateUnitQuantity(''), 'Enter unit qty');
      expect(validateUnitQuantity('   '), 'Enter unit qty');
      expect(validateUnitQuantity(null), 'Enter unit qty');
    });

    test('Negative numbers and zero return error', () {
      expect(validateUnitQuantity('-5'), 'Must be positive');
      expect(validateUnitQuantity('0'), 'Must be positive');
      expect(validateUnitQuantity('-1.5'), 'Must be positive');
    });

    test('Invalid alphabetic words and malformed fractions return error', () {
      expect(validateUnitQuantity('one'), 'Enter positive number or fraction (e.g. 1.5, 1/2)');
      expect(validateUnitQuantity('1/a'), 'Enter positive number or fraction (e.g. 1.5, 1/2)');
      expect(validateUnitQuantity('1/0'), 'Enter positive number or fraction (e.g. 1.5, 1/2)');
      expect(validateUnitQuantity('1/2/3'), 'Enter positive number or fraction (e.g. 1.5, 1/2)');
    });
  });

  group('Pricing and Cost Validation Tests', () {
    test('Valid pricing numbers return null', () {
      expect(validatePrice('0'), isNull);
      expect(validatePrice('120'), isNull);
      expect(validatePrice('45.50'), isNull);
    });

    test('Negative prices return error', () {
      expect(validatePrice('-1'), 'Price cannot be negative');
      expect(validatePrice('-10.50'), 'Price cannot be negative');
    });

    test('Non-numeric strings return error', () {
      expect(validatePrice('abc'), 'Enter valid price');
      expect(validatePrice(''), 'Enter a price');
      expect(validatePrice(null), 'Enter a price');
    });
  });

  group('Dashboard KPI Computation Tests', () {
    final mockMenuItems = [
      MenuItem(id: 1, name: 'Burger', unitType: 'portion', unitQuantity: '1', price: 100, costingStatus: 'approved', status: 'active'),
      MenuItem(id: 2, name: 'Pizza', unitType: 'portion', unitQuantity: '1', price: 250, costingStatus: 'complete', status: 'active'),
      MenuItem(id: 3, name: 'Fries', unitType: 'portion', unitQuantity: '1', price: 80, costingStatus: 'draft', status: 'active'),
      MenuItem(id: 4, name: 'Cola', unitType: 'portion', unitQuantity: '1', price: 40, costingStatus: 'none', status: 'inactive'),
    ];

    final mockInventoryItems = [
      InventoryItem(id: 1, name: 'Buns', quantity: 0), // Out of stock
      InventoryItem(id: 2, name: 'Cheese', quantity: 3), // Low stock
      InventoryItem(id: 3, name: 'Potatoes', quantity: 5), // Low stock (if threshold is 5)
      InventoryItem(id: 4, name: 'Cola Syrup', quantity: 12), // In stock
    ];

    test('Calculates active menu items correctly', () {
      final metrics = calculateDashboardMetrics(
        menuItems: mockMenuItems,
        inventoryItems: mockInventoryItems,
        lowStockThreshold: 5,
      );
      expect(metrics['activeMenuCount'], 3); // Burger, Pizza, Fries are active. Cola is inactive.
    });

    test('Calculates costing coverage percentage correctly', () {
      final metrics = calculateDashboardMetrics(
        menuItems: mockMenuItems,
        inventoryItems: mockInventoryItems,
        lowStockThreshold: 5,
      );
      // Burger (approved) is 1 out of 4 menu items.
      expect(metrics['costingCoverage'], 25.0);
    });

    test('Coverage calculation handles division-by-zero for empty menu items list', () {
      final metrics = calculateDashboardMetrics(
        menuItems: [],
        inventoryItems: mockInventoryItems,
        lowStockThreshold: 5,
      );
      expect(metrics['costingCoverage'], 0.0);
    });

    test('Identifies low stock metrics correctly for threshold = 5', () {
      final metrics = calculateDashboardMetrics(
        menuItems: mockMenuItems,
        inventoryItems: mockInventoryItems,
        lowStockThreshold: 5,
      );
      expect(metrics['outOfStockCount'], 1); // Buns (0)
      expect(metrics['lowStockCount'], 2); // Cheese (3), Potatoes (5)
    });

    test('Identifies low stock metrics dynamically shifts for threshold = 2', () {
      final metrics = calculateDashboardMetrics(
        menuItems: mockMenuItems,
        inventoryItems: mockInventoryItems,
        lowStockThreshold: 2,
      );
      expect(metrics['outOfStockCount'], 1); // Buns (0)
      expect(metrics['lowStockCount'], 0); // Cheese (3) and Potatoes (5) are now normal stock (> 2)
    });
  });
}
