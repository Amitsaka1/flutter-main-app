class Environment {

  // ── API (Backend) ─────────────────────────────
  static const String _apiUrl =
      "https://momo-qd13.onrender.com";

  static String get baseUrl => _apiUrl;

  // ── LiveKit Server ────────────────────────────
  static const String _livekitUrl =
      "wss://acceptable-marleen-amitsaka12345-ddc0c198.koyeb.app";

  static String get livekitUrl => _livekitUrl;

  // ── Environment flag ──────────────────────────
  static const bool _isProduction =
      bool.fromEnvironment('dart.vm.product');

  static bool get isProduction => _isProduction;

  // ── Legacy alias (do not remove) ─────────────
  static String get apiUrl => _apiUrl;
}
