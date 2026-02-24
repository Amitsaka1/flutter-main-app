import 'dart:async';
import '../network/api_client.dart';

class ChatController {
  // 🔥 Singleton
  ChatController._internal();
  static final ChatController _instance = ChatController._internal();
  static ChatController get instance => _instance;

  // 🔥 Internal State
  List<dynamic> _chats = [];
  bool _loading = false;
  DateTime? _lastFetch;

  final StreamController<List<dynamic>> _chatStreamController =
      StreamController.broadcast();

  Stream<List<dynamic>> get chatStream => _chatStreamController.stream;

  List<dynamic> get chats => _chats;

  bool get isLoading => _loading;

  bool get hasData => _chats.isNotEmpty;

  bool get isFresh {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!).inSeconds < 20;
  }

  // 🔥 Initial Load (with cache logic)
  Future<void> loadChats({bool forceRefresh = false}) async {
    if (_loading) return;

    if (!forceRefresh && hasData && isFresh) {
      _chatStreamController.add(_chats);
      return;
    }

    _loading = true;

    try {
      final response = await ApiClient.get("/chat/recent");

      if (response["success"] == true) {
        final data = response["data"] as List;

        _chats = data;
        _lastFetch = DateTime.now();

        _chatStreamController.add(_chats);
      }
    } catch (_) {}

    _loading = false;
  }

  // 🔥 Background Refresh
  Future<void> refresh() async {
    await loadChats(forceRefresh: true);
  }

  // 🔥 Update from Socket (NEW_MESSAGE)
  void handleNewMessage(dynamic message) {
    final senderId = message["senderId"];

    for (var chat in _chats) {
      if (chat["user"]["id"] == senderId) {
        chat["lastMessage"] =
            message["type"] == "image" ? "📷 Image" : message["content"];
        chat["unreadCount"] =
            (chat["unreadCount"] ?? 0) + 1;
      }
    }

    _chatStreamController.add(_chats);
  }

  // 🔥 Mark as Read
  void markAsRead(String userId) {
    for (var chat in _chats) {
      if (chat["user"]["id"] == userId) {
        chat["unreadCount"] = 0;
      }
    }

    _chatStreamController.add(_chats);
  }

  // 🔥 Dispose (future safe)
  void dispose() {
    _chatStreamController.close();
  }
}
