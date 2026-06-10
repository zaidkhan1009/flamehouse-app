import 'package:dio/dio.dart';
import '../../core/network.dart';
import '../../data/models/menu_models.dart';

class MenuService {
  final ApiClient _apiClient = ApiClient();

  // --- Menu Item CRUD ---
  Future<List<MenuItem>> fetchMenuItems({String? search}) async {
    try {
      final response = await _apiClient.dio.get(
        '/menu',
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => MenuItem.fromJson(json)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  Future<MenuItem?> createMenuItem({
    required String name,
    required String unitType,
    required String unitQuantity,
    required double price,
    required String status,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/menu',
        data: {
          'name': name,
          'unit_type': unitType,
          'unit_quantity': unitQuantity,
          'price': price,
          'status': status,
        },
      );
      if (response.statusCode == 200) {
        return MenuItem.fromJson(response.data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<bool> updateMenuItem({
    required int id,
    required String name,
    required String unitType,
    required String unitQuantity,
    required double price,
    required String status,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/menu/$id',
        data: {
          'name': name,
          'unit_type': unitType,
          'unit_quantity': unitQuantity,
          'price': price,
          'status': status,
        },
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<bool> updateMenuItemStatus(int id, String status) async {
    try {
      final response = await _apiClient.dio.put(
        '/menu/$id',
        data: {
          'status': status,
        },
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<bool> deleteMenuItem(int id) async {
    try {
      final response = await _apiClient.dio.delete('/menu/$id');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  // --- Menu Variant CRUD ---
  Future<List<MenuVariant>> fetchVariants(int menuId) async {
    try {
      final response = await _apiClient.dio.get('/menu-variants/$menuId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => MenuVariant.fromJson(json)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  Future<MenuVariant?> createVariant({
    required int menuId,
    required String variantName,
    required double servingPrice,
    required double deliveryPrice,
    required bool isActive,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/menu-variants/$menuId',
        data: {
          'variant_name': variantName,
          'serving_price': servingPrice,
          'delivery_price': deliveryPrice,
          'is_active': isActive,
        },
      );
      if (response.statusCode == 200) {
        return MenuVariant.fromJson(response.data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<bool> updateVariant({
    required int variantId,
    required String variantName,
    required double servingPrice,
    required double deliveryPrice,
    required bool isActive,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/menu-variants/item/$variantId',
        data: {
          'variant_name': variantName,
          'serving_price': servingPrice,
          'delivery_price': deliveryPrice,
          'is_active': isActive,
        },
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<bool> deleteVariant(int variantId) async {
    try {
      final response = await _apiClient.dio.delete('/menu-variants/item/$variantId');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }
}
