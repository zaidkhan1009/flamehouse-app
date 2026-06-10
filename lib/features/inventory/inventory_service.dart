import 'package:dio/dio.dart';
import '../../core/network.dart';
import '../../data/models/inventory_models.dart';

class InventoryService {
  final ApiClient _apiClient = ApiClient();

  // --- Categories ---
  Future<List<InventoryCategory>> fetchCategories({String? search}) async {
    try {
      final response = await _apiClient.dio.get(
        '/inventory-categories',
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => InventoryCategory.fromJson(json)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  Future<InventoryCategory?> createCategory(String name, String? description) async {
    try {
      final response = await _apiClient.dio.post(
        '/inventory-categories',
        data: {
          'name': name,
          'description': description,
        },
      );
      if (response.statusCode == 200) {
        return InventoryCategory.fromJson(response.data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<bool> updateCategory(int id, String name, String? description) async {
    try {
      final response = await _apiClient.dio.put(
        '/inventory-categories/$id',
        data: {
          'name': name,
          'description': description,
        },
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final response = await _apiClient.dio.delete('/inventory-categories/$id');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  // --- Items ---
  Future<List<InventoryItem>> fetchItems({String? search}) async {
    try {
      final response = await _apiClient.dio.get(
        '/items',
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => InventoryItem.fromJson(json)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  Future<InventoryItem?> createItem(String name, int quantity, int? inventoryTypeId) async {
    try {
      final response = await _apiClient.dio.post(
        '/items',
        data: {
          'name': name,
          'quantity': quantity,
          'inventory_type_id': inventoryTypeId,
        },
      );
      if (response.statusCode == 200) {
        return InventoryItem.fromJson(response.data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<bool> updateItem(int id, String name, int quantity, int? inventoryTypeId) async {
    try {
      final response = await _apiClient.dio.put(
        '/items/$id',
        data: {
          'name': name,
          'quantity': quantity,
          'inventory_type_id': inventoryTypeId,
        },
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    try {
      final response = await _apiClient.dio.delete('/items/$id');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }
}
