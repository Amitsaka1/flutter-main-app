import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'app.dart';

/// 🔥 Global Navigator Key
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 AUDIO HARDWARE SETUP (ULTRA FIX)
  await _setupAudio();

  runApp(const MyApp());
}

/// =========================
/// 🔥 AUDIO HARDWARE CONFIG
/// =========================
Future<void> _setupAudio() async {
  try {
    // 🔥 Force speaker (avoid wrong routing)
    await Hardware.instance.setSpeakerphoneOn(true);

    // 🔥 Prefer bluetooth/headphones if available
    await Hardware.instance.setBluetoothPreferred(true);

    debugPrint("✅ Audio hardware configured (ULTRA)");
  } catch (e) {
    debugPrint("❌ Audio setup error: $e");
  }
}
