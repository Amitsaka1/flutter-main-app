class Environment {
  static const String _devApiUrl =
      "https://momo-1etm.onrender.com";

  static const String _prodApiUrl =
      "https://momo-1etm.onrender.com";

  // 🔥 Detect production build
  static const bool _isProduction =
      bool.fromEnvironment('dart.vm.product');

  // 🔥 Public getter
  static String get apiUrl =>
      _isProduction ? _prodApiUrl : _devApiUrl;

  // 🔥 Optional: expose environment type (future logging use)
  static bool get isProduction => _isProduction;
}
