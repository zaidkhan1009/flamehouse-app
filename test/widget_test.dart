import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:flamehouse_app/main.dart';
import 'package:flamehouse_app/core/network.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock interceptor to test authentication outcomes
class MockAuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path.endsWith('/auth/login')) {
      final data = options.data as Map<String, dynamic>?;
      if (data != null && data['username'] == 'admin' && data['password'] == 'password') {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'access_token': 'mock-valid-token'},
        ));
      } else {
        handler.reject(DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {'detail': 'Invalid credentials'},
          ),
          type: DioExceptionType.badResponse,
        ));
      }
    } else {
      handler.next(options);
    }
  }
}

void main() {
  setUp(() async {
    // Reset SharedPreferences to guarantee test isolation
    SharedPreferences.setMockInitialValues({});

    // Load environment mock configuration
    await dotenv.load(fileName: ".env");
    
    // Clear and swap network layer interceptors with the Mock handler
    final apiClient = ApiClient();
    apiClient.dio.interceptors.clear();
    apiClient.dio.interceptors.add(MockAuthInterceptor());
  });

  testWidgets('Login Screen Form Validation and Render Test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Verify fields and buttons exist
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('Login Screen Negative Scenario - Invalid Credentials Error Display', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Enter wrong credentials
    await tester.enterText(find.byType(TextField).at(0), 'bad_username');
    await tester.enterText(find.byType(TextField).at(1), 'wrong_password');
    
    // Tap the Login button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle(); // Allow UI state and animations to resolve

    // Verify error text is displayed on the screen
    expect(find.text('Invalid username or password'), findsOneWidget);
  });

  testWidgets('Login Screen Positive Scenario - Correct Credentials Routing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Enter correct credentials
    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    
    // Tap the Login button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // Triggers the tap event
    await tester.pump(const Duration(milliseconds: 100)); // Resolves the async login network request
    await tester.pump(const Duration(milliseconds: 100)); // Triggers routing push
    await tester.pump(const Duration(milliseconds: 300)); // Completes the page slide transition

    // Verify snackbar or dashboard screen title is loaded indicating successful route push
    expect(find.text('Login successful!'), findsOneWidget);
    expect(find.text('Viral Bytes Console'), findsOneWidget);
  });

  testWidgets('Login Bug Repro - Invalid then Valid credentials', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // 1. Enter wrong credentials
    await tester.enterText(find.byType(TextField).at(0), 'bad_username');
    await tester.enterText(find.byType(TextField).at(1), 'wrong_password');
    
    // Tap the Login button
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify error text is displayed
    expect(find.text('Invalid username or password'), findsOneWidget);

    // 2. Enter correct credentials
    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    
    // Tap the Login button
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // Triggers the tap event
    await tester.pump(const Duration(milliseconds: 100)); // Resolves the async login network request
    await tester.pump(const Duration(milliseconds: 100)); // Triggers routing push
    await tester.pump(const Duration(milliseconds: 300)); // Completes the page slide transition

    // Verify snackbar indicating successful route push
    expect(find.text('Login successful!'), findsOneWidget);
    expect(find.text('Viral Bytes Console'), findsOneWidget);
  });
}
