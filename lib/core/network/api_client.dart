import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl =
      "https://momo-1etm.onrender.com";

  static String? _token;

  // ================= TOKEN =================

  static Future<void> saveToken(String token) async {
    _token = token;
  }

  static Future<String?> getToken() async {
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
  }

  // ================= GET =================

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

    return _handleResponse(response);
  }

  // ================= POST =================

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

    return _handleResponse(response);
  }

  // ================= PUT (🔥 ADDED) =================

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse("$baseUrl$endpoint");

    final response = await http.put(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // ================= COMMON RESPONSE HANDLER =================

  static Map<String, dynamic> _handleResponse(
      http.Response response) {
    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return decoded;
    } else {
      throw Exception(
          decoded["message"] ?? "Server error");
    }
  }

  // ================= HEADERS =================

  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (_token != null)
        "Authorization": "Bearer $_token",
    };
  }
}
