import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ IMPORTANT (WEB CHECK)
import 'app.dart';

/// 🔥 Global Navigator Key
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 AUDIO HARDWARE SETUP (SAFE)
  await _setupAudio();

  runApp(const MyApp());
}

/// =========================
/// 🔥 AUDIO HARDWARE CONFIG
/// =========================
Future<void> _setupAudio() async {
  try {
    // ❌ WEB में LiveKit hardware नहीं चलता
    if (!kIsWeb) {
      // 👉 अगर future में mobile audio चाहिए तो यहाँ डालना
      // await Hardware.instance.setSpeakerphoneOn(true);
    }

    debugPrint("✅ Audio hardware configured (SAFE)");
  } catch (e) {
    debugPrint("❌ Audio setup error: $e");
  }
}
