// ✅ FIX: Environment config — dart-define se URLs lo, hardcode nahi
//
// Problem: URLs seedhe code mein thi — server change = file edit + rebuild
//          Dev aur Production alag nahi the — test data production mein jaata tha
//
// Fix: --dart-define se URLs inject karo build time pe
//      Agar dart-define nahi diya → production defaults use hote hain
//      Koi breaking change nahi — saare getters same hain
//
// ──────────────────────────────────────────────────────────────
// HOW TO USE:
//
// 🔴 Production build (Play Store):
//   flutter build apk --release
//   (defaults automatically production URLs use karenge)
//
// 🟡 Staging build:
//   flutter build apk --dart-define=API_URL=https://momo-staging.onrender.com
//
// 🟢 Local development:
//   flutter run --dart-define=API_URL=http://192.168.1.5:3000
//   (apna local IP dalo — emulator localhost nahi hota)
//
// ──────────────────────────────────────────────────────────────

class Environment {

  // ✅ FIX: Hardcoded URL → dart-define se lo
  //
  // Pehle:
  //   static const String _apiUrl = "https://momo-qd13.onrender.com";
  //
  // Ab:
  //   Build time pe --dart-define=API_URL=https://... se inject karo
  //   Agar dart-define nahi diya → production URL default hai
  //   Matlab existing Play Store build bilkul same kaam karega — no change
  //
  static const String _apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://momo-qd13.onrender.com', // ✅ Same production URL
  );

  // ✅ Centrifugo WebSocket URL
  static const String _centrifugoUrl = String.fromEnvironment(
    'CENTRIFUGO_URL',
    defaultValue: 'wss://momo-centryfugo.onrender.com/connection/websocket',
  );

  // ✅ FIX: isProduction ab sahi se kaam karta hai
  //
  // Pehle: sirf dart.vm.product check karta tha
  //        flutter run (debug) = false, flutter build = true
  //        Lekin staging build bhi "production" lagta tha
  //
  // Ab: Agar explicitly DEV_MODE=true pass kiya → development
  //     Baaki sab cases mein dart.vm.product check karo
  //
  static const bool _devMode = bool.fromEnvironment(
    'DEV_MODE',
    defaultValue: false,
  );

  static const bool _dartProduction =
      bool.fromEnvironment('dart.vm.product');

  static String get baseUrl        => _apiUrl;
  static String get centrifugoUrl  => _centrifugoUrl;
  static String get apiUrl         => _apiUrl;

  static bool get isProduction => _dartProduction && !_devMode;

  // ✅ Debug logging ke liye useful
  // Koi bhi screen pe show kar sako current config — debugging easy
  static void printConfig() {
    if (!isProduction) {
      print("🔧 Environment Config:");
      print("   API URL     : $_apiUrl");
      print("   Centrifugo  : $_centrifugoUrl");
      print("   Production  : $isProduction");
      print("   Dev Mode    : $_devMode");
    }
  }
}
