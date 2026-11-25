import 'package:dio/dio.dart';

/// Creates the shared HTTP client for the MockAPI service.
class DioClient {
  static const String _apiKey = String.fromEnvironment('MOCKAPI_KEY');

  static bool get hasApiKey => _apiKey.isNotEmpty;

  /// Builds a client that lets Dio report missing-key failures normally.
  ///
  /// This lets the repository fall back to SQLite when the app is offline.
  static Dio create({String? apiKey}) {
    final configuredApiKey = (apiKey ?? _apiKey).trim();
    final headers = <String, String>{'Accept': 'application/json'};
    if (configuredApiKey.isNotEmpty) {
      headers['x-api-key'] = configuredApiKey;
    }

    return Dio(
      BaseOptions(
        baseUrl: 'https://api.mockapi.com',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: headers,
      ),
    );
  }
}
