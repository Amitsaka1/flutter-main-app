import 'dart:async';
import '../network/api_client.dart';

class ChatController {
  // ================= SINGLETON =================
  ChatController._internal();
  static final ChatController _instance = ChatController._internal();
  static ChatController get instance => _instance;

  // ================= STATE =================
  List<dynamic> _chats = [];
  bool _loading = false;
  DateTime? _lastFetch;

  /// 🔥 loaded flag (instant open)
  bool _loaded = false;

  final StreamController<List<dynamic>> _chatStreamController =
      StreamController.broadcast();

  Stream<List<dynamic>> get chatStream => _chatStreamController.stream;

  // ================= GETTERS =================
  List<dynamic> get chats => List.from(_chats);

  bool get isLoading => _loading;

  bool get hasData => _loaded && _chats.isNotEmpty;

  bool get isFresh {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!).inSeconds < 20;
  }

  // ================= LOAD =================
  Future<void> loadChats({bool forceRefresh = false}) async {
    if (_loading) return;

    // 🔥 instant cache return
    if (!forceRefresh && _loaded) {
      _chatStreamController.add(List.from(_chats));
      return;
    }

    _loading = true;

    try {
      final response = await ApiClient.get("/chat/recent");

      if (response["success"] == true) {
        final data = response["data"] as List;

        _chats = List.from(data);
        _lastFetch = DateTime.now();
      }
    } catch (_) {
      // ignore error (UI will still update)
    }

    // 🔥 IMPORTANT: always mark loaded
    _loaded = true;

    _loading = false;

    // 🔥 ALWAYS emit (even if empty / failed)
    _chatStreamController.add(List.from(_chats));
  }

  // ================= REFRESH =================
  Future<void> refresh() async {
    await loadChats(forceRefresh: true);
  }

  // ================= SOCKET UPDATE =================
  void handleNewMessage(dynamic message) {

  final senderId = message["senderId"];
  final receiverId = message["receiverId"];

  final chatUserId = senderId == _myId
      ? receiverId
      : senderId;

  final updatedChats = List<dynamic>.from(_chats);

  bool found = false;

  for (int i = 0; i < updatedChats.length; i++) {
    final chat = updatedChats[i];

    if (chat["user"]["id"] == chatUserId) {
      updatedChats[i] = {
        ...chat,
        "lastMessage": message["content"],
        "unreadCount": (chat["unreadCount"] ?? 0) + 1,
      };
      found = true;
      break;
    }
  }

  // 🔥 NEW CHAT ADD (IMPORTANT FIX)
  if (!found) {
    updatedChats.insert(0, {
      "user": {
        "id": chatUserId,
        "phone": "New User",
      },
      "lastMessage": message["content"],
      "unreadCount": 1,
    });
  }

  _chats = updatedChats;

  _chatStreamController.add(List.from(_chats));
  }

  // ================= MARK READ =================
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

  // ================= RESET (LOGOUT SAFE) =================
  void reset() {
    _chats = [];
    _loaded = false;
    _lastFetch = null;

    _chatStreamController.add([]);
  }

  // ================= DISPOSE =================
  void dispose() {
    _chatStreamController.close();
  }
}
