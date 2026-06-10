// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flamehouse_app/features/auth/auth_service.dart';

void main() {
  setUpAll(() async {
    // We load the local development .env config
    await dotenv.load(fileName: ".env");
    SharedPreferences.setMockInitialValues({});
  });

  test('Local API Integration: Invalid then Valid login with pre-existing expired token', () async {
    final authService = AuthService();

    // Set a dummy/expired token in SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', 'expired-dummy-token-value');

    // 1. Invalid attempt
    print("Sending invalid attempt...");
    final firstResult = await authService.login('admin', 'wrong-password');
    print("Invalid attempt result: $firstResult");
    expect(firstResult, equals('Invalid username or password'));

    // Verify token is still there (since /auth/login 401 doesn't clear it in current implementation)
    final tokenAfterFailed = prefs.getString('access_token');
    print("Token in SharedPreferences after failed login: $tokenAfterFailed");
    expect(tokenAfterFailed, equals('expired-dummy-token-value'));

    // 2. Valid attempt
    print("Sending valid attempt...");
    final secondResult = await authService.login('admin', 'password');
    print("Valid attempt result: $secondResult");
    expect(secondResult, isNull);
  });
}
