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

  // 🔥 Return copy (mutation safe)
  List<dynamic> get chats => List.from(_chats);

  bool get isLoading => _loading;

  bool get hasData => _chats.isNotEmpty;

  bool get isFresh {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!).inSeconds < 20;
  }

  // 🔥 Initial Load
  Future<void> loadChats({bool forceRefresh = false}) async {
    if (_loading) return;

    if (!forceRefresh && hasData && isFresh) {
      _chatStreamController.add(List.from(_chats));
      return;
    }

    _loading = true;

    try {
      final response = await ApiClient.get("/chat/recent");

      if (response["success"] == true) {
        final data = response["data"] as List;

        _chats = List.from(data); // 🔥 safe copy
        _lastFetch = DateTime.now();

        _chatStreamController.add(List.from(_chats));
      }
    } catch (_) {}

    _loading = false;
  }

  // 🔥 Background Refresh
  Future<void> refresh() async {
    await loadChats(forceRefresh: true);
  }

  // 🔥 Update from Socket
  void handleNewMessage(dynamic message) {
    final senderId = message["senderId"] ?? message["receiverId"];
    final updatedChats = List<dynamic>.from(_chats);

    for (int i = 0; i < updatedChats.length; i++) {
      final chat = updatedChats[i];

      if (chat["user"]["id"] == senderId) {
        updatedChats[i] = {
          ...chat,
          "lastMessage":
              message["type"] == "image"
                  ? "📷 Image"
                  : message["content"],
          "unreadCount":
              (chat["unreadCount"] ?? 0) + 1,
        };
        break;
      }
    }

    _chats = updatedChats;

    _chatStreamController.add(List.from(_chats));
  }

  // 🔥 Mark as Read
  void markAsRead(String userId) {
    final updatedChats = List<dynamic>.from(_chats);

    for (int i = 0; i < updatedChats.length; i++) {
      final chat = updatedChats[i];

      if (chat["user"]["id"] == userId) {
        updatedChats[i] = {
          ...chat,
          "unreadCount": 0,
        };
        break;
      }
    }

    _chats = updatedChats;

    _chatStreamController.add(List.from(_chats));
  }

  void dispose() {
    _chatStreamController.close();
  }
}
