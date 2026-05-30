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

  // ✅ FIX: LiveKit URL bhi dart-define se
  //
  // Pehle: hardcoded Koyeb URL
  // Ab: inject karo, default production URL same hai
  //
  static const String _livekitUrl = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'wss://acceptable-marleen-amitsaka12345-ddc0c198.koyeb.app',
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

  // ── ✅ UNCHANGED: Saare getters same hain — koi breaking change nahi ──

  static String get baseUrl    => _apiUrl;
  static String get livekitUrl => _livekitUrl;
  static String get apiUrl     => _apiUrl; // ✅ Legacy alias — unchanged

  // ✅ FIX: isProduction — devMode explicitly set ho toh false
  static bool   get isProduction => _dartProduction && !_devMode;

  // ✅ NEW: Debug logging ke liye useful
  // Koi bhi screen pe show kar sako current config — debugging easy
  static void printConfig() {
    if (!isProduction) {
      print("🔧 Environment Config:");
      print("   API URL     : $_apiUrl");
      print("   LiveKit URL : $_livekitUrl");
      print("   Production  : $isProduction");
      print("   Dev Mode    : $_devMode");
    }
  }
}
