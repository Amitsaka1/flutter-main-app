import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:app_project/core/config/environment.dart';

// ✅ FIX #1: flutter_secure_storage import
//
// Problem: Token sirf memory (_token variable) mein tha
//          App restart hone pe token wipe — user logout ho jaata tha
//          Aur agar SharedPreferences use karo toh plain text — insecure
//
// Fix: flutter_secure_storage — Android Keystore / iOS Keychain use karta hai
//      Token encrypted store hota hai — rooted phone se bhi nahi nikalega
//
// pubspec.yaml mein add karo:
//   flutter_secure_storage: ^9.0.0
//
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/global_data_manager.dart';
import '../network/sync_service.dart';

class ApiClient {
  static String get baseUrl => Environment.baseUrl;

  // ✅ FIX #1: In-memory _token + secure persistent storage
  // Memory cache: Fast access ke liye (har baar storage read nahi karna)
  // Secure storage: App restart ke baad bhi token rahe
  static String? _token;
  static const _storage    = FlutterSecureStorage();
  static const _tokenKey   = 'auth_token';

  // ✅ FIX #2: Timeout 70s → 15s
  //
  // Problem: 70 seconds bahut zyada hai
  //          Server slow ho toh Flutter 70s tak freeze — user sochta app hang hua
  //
  // Fix: 15 second — agar server 15s mein respond nahi kar sakta
  //      kuch serious problem hai, user ko turant batao
  //
  static const Duration _timeout = Duration(seconds: 15);

  // ✅ FIX #3: Retry config
  static const int _maxRetries = 2; // Total 3 attempts (1 original + 2 retries)

  // ================= TOKEN — FIXED =================

  // ✅ FIX #1: Save token dono jagah — memory + secure storage
  static Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  // ✅ FIX #1: Pehle memory check karo (fast), phir secure storage (persistent)
  static Future<String?> getToken() async {
    if (_token != null) return _token; // Memory cache hit — fast path
    _token = await _storage.read(key: _tokenKey); // App restart ke baad yahan se milega
    return _token;
  }

  // ✅ FIX #1: Clear dono jagah se
  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  // ================= RETRY HELPER — NEW =================

  // ✅ FIX #3: Retry with Exponential Backoff
  //
  // Problem: Network thodi der ke liye drop ho — request ek baar fail, bas
  //          User ko manually refresh karna padta tha
  //
  // Fix: 2 retries with exponential backoff + jitter
  //      Attempt 1: turant
  //      Retry 1:   1s wait  (+ random jitter)
  //      Retry 2:   2s wait  (+ random jitter)
  //
  // Retry SIRF in errors pe:
  //   ✅ SocketException (network drop)
  //   ✅ TimeoutException (server slow)
  //   ✅ 5xx server errors (temporary server issue)
  //
  // Retry NAHI in errors pe:
  //   ❌ 401 (token expired — retry karna bekaar hai)
  //   ❌ 400/404 (client error — data galat hai, retry se nahi thikega)
  //
  static Future<Map<String, dynamic>> _withRetry(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    int attempt = 0;

    while (true) {
      try {
        return await request();

      } on _RetryableException catch (e) {
        // ✅ Retryable error — wait karke dobara try karo
        if (attempt >= _maxRetries) rethrow; // Max retries ho gaye — throw karo

        attempt++;
        final delayMs = (pow(2, attempt) * 500 + Random().nextInt(300)).toInt();
        // Attempt 1: ~1000-1300ms, Attempt 2: ~2000-2300ms

        print("⚠️ Retry $attempt/$_maxRetries after ${delayMs}ms — ${e.message}");
        await Future.delayed(Duration(milliseconds: delayMs));

      } catch (e) {
        // ❌ Non-retryable error (401, 400, etc.) — turant throw karo
        rethrow;
      }
    }
  }

  // ================= CONNECTIVITY CHECK — NEW =================

  static Future<bool> hasInternet() async {
    try {
      final uri = Uri.parse("$baseUrl/health");
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ================= GET — FIXED =================

  // ✅ UNCHANGED: Same signature — koi breaking change nahi
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    return _withRetry(() async {
      final uri = Uri.parse("$baseUrl$endpoint")
          .replace(queryParameters: queryParams);

      try {
        final response = await http
            .get(uri, headers: await _headers())
            .timeout(_timeout);

        return _handleResponse(response);

      } on TimeoutException {
        throw _RetryableException("Request timeout");  // ✅ Retry hoga
      } on SocketException {
        throw _RetryableException("No internet connection"); // ✅ Retry hoga
      }
    });
  }

  // ================= POST — FIXED =================

  // ✅ UNCHANGED: Same signature
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _withRetry(() async {
      final uri = Uri.parse("$baseUrl$endpoint");

      try {
        final response = await http
            .post(
              uri,
              headers: await _headers(),
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        return _handleResponse(response);

      } on TimeoutException {
        throw _RetryableException("Request timeout");
      } on SocketException {
        throw _RetryableException("No internet connection");
      }
    });
  }

  // ================= PUT — FIXED =================

  // ✅ UNCHANGED: Same signature
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _withRetry(() async {
      final uri = Uri.parse("$baseUrl$endpoint");

      try {
        final response = await http
            .put(
              uri,
              headers: await _headers(),
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        return _handleResponse(response);

      } on TimeoutException {
        throw _RetryableException("Request timeout");
      } on SocketException {
        throw _RetryableException("No internet connection");
      }
    });
  }

  // ================= PATCH — NEW =================

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _withRetry(() async {
      final uri = Uri.parse("$baseUrl$endpoint");

      try {
        final response = await http
            .patch(
              uri,
              headers: await _headers(),
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        return _handleResponse(response);

      } on TimeoutException {
        throw _RetryableException("Request timeout");
      } on SocketException {
        throw _RetryableException("No internet connection");
      }
    });
  }

  // ================= DELETE — NEW =================

  static Future<Map<String, dynamic>> delete(
    String endpoint,
  ) async {
    return _withRetry(() async {
      final uri = Uri.parse("$baseUrl$endpoint");

      try {
        final response = await http
            .delete(uri, headers: await _headers())
            .timeout(_timeout);

        return _handleResponse(response);

      } on TimeoutException {
        throw _RetryableException("Request timeout");
      } on SocketException {
        throw _RetryableException("No internet connection");
      }
    });
  }

  // ================= MULTIPART — ✅ UNCHANGED =================

  static Future<Map<String, dynamic>> multipart(
    String endpoint,
    File file, {
    String fieldName = "file",
  }) async {
    final uri = Uri.parse("$baseUrl$endpoint");

    try {
      final request = http.MultipartRequest("POST", uri);

      final token = await getToken(); // ✅ FIX: await karo — async ho gaya
      if (token != null) {
        request.headers["Authorization"] = "Bearer $token";
      }

      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );

      // ✅ FIX: Timeout 70s → 30s (upload ke liye thoda zyada OK hai)
      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 30));

      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);

    } on TimeoutException {
      throw Exception("Upload timeout");
    } on SocketException {
      throw Exception("No internet connection");
    }
  }

  // ================= UPLOAD PROFILE IMAGE — ✅ UNCHANGED =================

  static Future<String> uploadProfileImage(String filePath) async {
    final uri = Uri.parse("$baseUrl/profile/upload-avatar");

    final request = http.MultipartRequest("POST", uri);

    final token = await getToken();
    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    request.files.add(
      await http.MultipartFile.fromPath("file", filePath),
    );

    final response  = await request.send();
    final resBody   = await response.stream.bytesToString();
    final decoded   = jsonDecode(resBody);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded["avatarUrl"];
    } else {
      throw Exception(decoded["message"] ?? "Upload failed");
    }
  }

  // ================= RESPONSE HANDLER — FIXED =================

  static Map<String, dynamic> _handleResponse(http.Response response) {

    // ✅ UNCHANGED: Empty response check
    if (response.body.isEmpty) {
      throw Exception("Empty server response");
    }

    final decoded = jsonDecode(response.body);

    // ✅ UNCHANGED: Success
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    // ✅ UNCHANGED: 401 — token clear karo
    if (response.statusCode == 401) {
      clearToken();
      // ✅ NAYA: Cache bhi clear karo — purana data na rahe
      GlobalDataManager.instance.clear();
      SyncService.instance.stop();
      throw Exception("Session expired");
    }

    // ✅ FIX #3: 5xx Server errors — retryable mark karo
    //
    // Problem: Pehle 500 error pe bhi retry nahi hota tha
    //          Temporary server hiccup pe user ko error dikh jaata tha
    //
    // Fix: 500/502/503/504 pe retry — ye temporary errors hote hain
    //
    if (response.statusCode >= 500) {
      throw _RetryableException(
        decoded["message"] ?? "Server error (${response.statusCode})"
      );
    }

    // ✅ UNCHANGED: Baaki errors (400, 404, etc.)
    throw Exception(decoded["message"] ?? "Server error");
  }

  // ================= HEADERS — FIXED =================

  // ✅ FIX: _headers async ho gaya — getToken() await karta hai
  // Pehle synchronous tha toh sirf in-memory _token check hota
  // Ab secure storage se bhi token milega agar memory mein nahi hai
  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }
}

// ================= RETRYABLE EXCEPTION — NEW =================

// ✅ FIX: Internal class — retry logic ko signal karta hai
// Normal Exception se alag hai — sirf isse retry hoga
// User-facing error message same rehta hai
class _RetryableException implements Exception {
  final String message;
  const _RetryableException(this.message);

  @override
  String toString() => message;
}
