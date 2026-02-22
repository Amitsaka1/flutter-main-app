class Environment {
  static const String _devApiUrl = "https://momo-1etm.onrender.com";
  static const String _prodApiUrl = "https://momo-1etm.onrender.com";

  static const bool _isProduction = bool.fromEnvironment(
    'dart.vm.product',
  );

  static String get apiUrl =>
      _isProduction ? _prodApiUrl : _devApiUrl;
}
