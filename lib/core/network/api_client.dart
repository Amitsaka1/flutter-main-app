import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl =
      "https://momo-qd13.onrender.com";

  static String? _token;

  static const Duration _timeout =
      Duration(seconds: 40);

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

    try {
      final response = await http
          .get(uri, headers: _headers())
          .timeout(_timeout);

      return _handleResponse(response);

    } on TimeoutException {
      throw Exception("Request timeout");
    } on SocketException {
      throw Exception("No internet connection");
    }
  }

  // ================= POST =================

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse("$baseUrl$endpoint");

    try {
      final response = await http
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _handleResponse(response);

    } on TimeoutException {
      throw Exception("Request timeout");
    } on SocketException {
      throw Exception("No internet connection");
    }
  }

  // ================= PUT =================

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse("$baseUrl$endpoint");

    try {
      final response = await http
          .put(
            uri,
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _handleResponse(response);

    } on TimeoutException {
      throw Exception("Request timeout");
    } on SocketException {
      throw Exception("No internet connection");
    }
  }

  // ================= MULTIPART (🔥 ADDED) =================

  static Future<Map<String, dynamic>> multipart(
    String endpoint,
    File file, {
    String fieldName = "file",
  }) async {
    final uri = Uri.parse("$baseUrl$endpoint");

    try {
      final request = http.MultipartRequest("POST", uri);

      // 🔐 token
      if (_token != null) {
        request.headers["Authorization"] = "Bearer $_token";
      }

      // 📦 file attach
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
        ),
      );

      final streamedResponse =
          await request.send().timeout(_timeout);

      final response =
          await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);

    } on TimeoutException {
      throw Exception("Upload timeout");
    } on SocketException {
      throw Exception("No internet connection");
    }
  }

  // upload avatar

  static Future<String> uploadProfileImage(String filePath) async {
  final uri = Uri.parse("$baseUrl/profile/upload-avatar");

  final request = http.MultipartRequest("POST", uri);

  final token = await getToken();

  if (token != null) {
    request.headers["Authorization"] = "Bearer $token";
  }

  request.files.add(
    await http.MultipartFile.fromPath(
      "file",
      filePath,
    ),
  );

  final response = await request.send();

  final resBody = await response.stream.bytesToString();
  final decoded = jsonDecode(resBody);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return decoded["avatarUrl"];
  } else {
    throw Exception(decoded["message"] ?? "Upload failed");
  }
  }

  // ================= RESPONSE HANDLER =================

  static Map<String, dynamic> _handleResponse(
      http.Response response) {

    if (response.body.isEmpty) {
      throw Exception("Empty server response");
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return decoded;
    }

    if (response.statusCode == 401) {
      clearToken();
      throw Exception("Session expired");
    }

    throw Exception(
        decoded["message"] ?? "Server error");
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
