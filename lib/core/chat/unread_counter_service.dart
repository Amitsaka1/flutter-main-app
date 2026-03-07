import 'dart:async';

class UnreadCounterService {

  static final Map<String, int> _chatUnread = {};
  static int _totalUnread = 0;

  static final StreamController<Map<String, int>> _chatController =
      StreamController.broadcast();

  static final StreamController<int> _totalController =
      StreamController.broadcast();

  static Stream<Map<String, int>> get chatStream =>
      _chatController.stream;

  static Stream<int> get totalStream =>
      _totalController.stream;

  static int get totalUnread => _totalUnread;

  // 🔥 new message
  static void increment(String chatId) {

    _chatUnread[chatId] =
        (_chatUnread[chatId] ?? 0) + 1;

    _totalUnread++;

    _chatController.add(Map.from(_chatUnread));
    _totalController.add(_totalUnread);
  }

  // 🔥 open chat
  static void clearChat(String chatId) {

    int removed = _chatUnread[chatId] ?? 0;

    _totalUnread -= removed;

    _chatUnread[chatId] = 0;

    _chatController.add(Map.from(_chatUnread));
    _totalController.add(_totalUnread);
  }

  // 🔥 after login
  static void setInitial(int total) {
    _totalUnread = total;
    _totalController.add(_totalUnread);
  }
}
