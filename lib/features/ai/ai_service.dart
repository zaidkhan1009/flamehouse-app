import 'package:dio/dio.dart';
import '../../core/network.dart';

class AISuggestion {
  final String recommendation;
  final String confidence;
  final Map<String, dynamic> metadata;

  AISuggestion({
    required this.recommendation,
    required this.confidence,
    required this.metadata,
  });

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      recommendation: json['recommendation'],
      confidence: json['confidence'] ?? 'medium',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class AIService {
  final ApiClient _apiClient = ApiClient();

  Future<AISuggestion?> fetchSuggestion(String feature, Map<String, dynamic> context) async {
    try {
      final response = await _apiClient.dio.post(
        '/ai/suggestions',
        data: {
          'feature': feature,
          'context': context,
        },
      );
      if (response.statusCode == 200) {
        return AISuggestion.fromJson(response.data);
      }
      return null;
    } on DioException {
      return null;
    }
  }
}
