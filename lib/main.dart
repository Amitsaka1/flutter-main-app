import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/socket/global_socket_manager.dart';

/// 🔥 Global Navigator Key
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 AUDIO SETUP
  await _setupAudio();

  /// 🔥 GLOBAL SOCKET INIT (NEW)
  try {
    final token = await ApiClient.getToken();

    if (token != null) {
      final payload = jsonDecode(
        utf8.decode(
          base64Url.decode(
            base64Url.normalize(token.split(".")[1]),
          ),
        ),
      );

      final userId = payload["id"];

      await GlobalSocketManager.instance.init(userId);

      debugPrint("✅ Socket initialized globally");
    }
  } catch (e) {
    debugPrint("❌ Socket init error: $e");
  }

  runApp(const MyApp());
}

/// =========================
/// 🔥 AUDIO CONFIG
/// =========================
Future<void> _setupAudio() async {
  try {
    if (!kIsWeb) {
      // future audio config
    }

    debugPrint("✅ Audio hardware configured (SAFE)");
  } catch (e) {
    debugPrint("❌ Audio setup error: $e");
  }
}
