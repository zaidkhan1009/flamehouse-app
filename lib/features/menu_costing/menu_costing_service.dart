import 'package:dio/dio.dart';
import '../../core/network.dart';
import '../../data/models/menu_models.dart';
import '../../data/models/costing_models.dart';

class MenuCostingService {
  final ApiClient _apiClient = ApiClient();

  Future<List<MenuCostingOverviewItem>> fetchOverview() async {
    try {
      final response = await _apiClient.dio.get('/menu-costing');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => MenuCostingOverviewItem.fromJson(json)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  Future<int?> createCostingSession(int menuItemId) async {
    try {
      final response = await _apiClient.dio.post(
        '/menu-costing',
        data: {'menu_item_id': menuItemId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['id'];
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<MenuCosting?> getCosting(int costingId) async {
    try {
      final response = await _apiClient.dio.get('/menu-costing/$costingId');
      if (response.statusCode == 200) {
        return MenuCosting.fromJson(response.data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<bool> deleteCosting(int costingId) async {
    try {
      final response = await _apiClient.dio.delete('/menu-costing/$costingId');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<bool> savePrep(int costingId, List<CostingPrepItem> items) async {
    try {
      final response = await _apiClient.dio.post(
        '/menu-costing/$costingId/prep',
        data: items.map((e) => e.toJson()).toList(),
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<bool> saveOverhead(int costingId, List<CostingOverheadItem> items) async {
    try {
      final response = await _apiClient.dio.post(
        '/menu-costing/$costingId/overhead',
        data: items.map((e) => e.toJson()).toList(),
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<bool> savePacking(int costingId, List<CostingPackingItem> items) async {
    try {
      final response = await _apiClient.dio.post(
        '/menu-costing/$costingId/packing',
        data: items.map((e) => e.toJson()).toList(),
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<bool> saveFinal(int costingId, CostingFinal finalCosting) async {
    try {
      final response = await _apiClient.dio.put(
        '/menu-costing/$costingId/final',
        data: finalCosting.toJson(),
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<Map<String, dynamic>?> approveCosting(int costingId) async {
    try {
      final response = await _apiClient.dio.post('/menu-costing/$costingId/approve');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException {
      return null;
    }
  }
}
