import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = "https://momo-1etm.onrender.com";

  static String? _token;

  static Future<void> saveToken(String token) async {
    _token = token;
  }

  static Future<String?> getToken() async {
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse("$baseUrl$endpoint")
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse("$baseUrl$endpoint");

    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (_token != null) "Authorization": "Bearer $_token",
    };
  }
}
