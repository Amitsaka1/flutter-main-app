class AppDebug {

  static final List<String> _logs = [];

  static List<String> get logs => _logs;

  static void log(String message) {

    final time = DateTime.now().toIso8601String();

    final logMsg = "[$time] $message";

    _logs.add(logMsg);

    // console में भी दिखे
    print(logMsg);

    // memory safe (max 200 logs)
    if (_logs.length > 200) {
      _logs.removeAt(0);
    }

  }

  static void clear() {
    _logs.clear();
  }

}
