import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<String?> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['access_token'] != null) {
        final token = response.data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        return null;
      }
      return 'Invalid username or password';
    } on DioException catch (e) {
      // ignore: avoid_print
      print("LOGIN ERROR: type=${e.type}, message=${e.message}, status=${e.response?.statusCode}, response=${e.response?.data}");
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Connection failed. Please check your network or server status.';
      }
      if (e.response?.statusCode == 401) {
        return 'Invalid username or password';
      }
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }
}
