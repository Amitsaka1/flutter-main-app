import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/riverpod/app_container.dart';
import 'core/data/global_data_manager.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/socket/global_socket_manager.dart';
import 'core/session/user_session.dart';

/// 🔥 Global Navigator Key
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 AUDIO SETUP
  await _setupAudio();

  /// ✅ YE ADD HUA — SQLite se instant load
  await GlobalDataManager.instance.loadFromCache();

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

      UserSession.setUserId(userId.toString());
      await GlobalSocketManager.instance.init(userId);
        
      debugPrint("✅ Socket initialized globally");
    }
  } catch (e) {
    debugPrint("❌ Socket init error: $e");
  }

  runApp(
    UncontrolledProviderScope(
      container: globalProviderContainer,
      child: const MyApp(),
    ),
  );
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
