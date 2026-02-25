import 'dart:async';
import '../network/api_client.dart';
import '../socket/global_socket_manager.dart';

class ConversationController {
  ConversationController._internal();
  static final ConversationController _instance =
      ConversationController._internal();
  static ConversationController get instance => _instance;

  final Map<String, List<dynamic>> _conversationCache = {};
  final Map<String, StreamController<List<dynamic>>> _streams = {};

  String? _myId;
  bool _socketInitialized = false;
  StreamSubscription? _socketSub;

  // ================= INIT =================

  void init(String myId) {
    if (_socketInitialized && _myId == myId) return;

    _myId = myId;

    GlobalSocketManager.instance.init(myId);

    _socketSub?.cancel();
    _socketSub = GlobalSocketManager.instance.messages
        .listen(_handleSocket);

    _socketInitialized = true;
  }

  // ================= STREAM =================

  Stream<List<dynamic>> stream(String userId) {
    _streams[userId] ??= StreamController.broadcast();
    return _streams[userId]!.stream;
  }

  List<dynamic> getMessages(String userId) {
    return List.from(_conversationCache[userId] ?? []);
  }

  // ================= LOAD =================

  Future<void> loadMessages(String userId) async {
    if (_conversationCache.containsKey(userId)) {
      _emit(userId);
    }

    try {
      final response =
          await ApiClient.get("/chat/messages/$userId");

      if (response["success"] == true) {
        _conversationCache[userId] =
            List.from(response["data"]);

        await ApiClient.post("/chat/mark-read", {
          "senderId": userId
        });

        _emit(userId);
      }
    } catch (_) {}
  }

  // ================= SEND =================

  Future<void> sendMessage(
      String userId, String content) async {
    if (_myId == null) return;

    final tempMessage = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "senderId": _myId,
      "receiverId": userId,
      "content": content,
      "isRead": false,
    };

    _conversationCache[userId] ??= [];

    final updated =
        List<dynamic>.from(_conversationCache[userId]!);
    updated.add(tempMessage);

    _conversationCache[userId] = updated;

    _emit(userId);

    try {
      await ApiClient.post("/chat/send", {
        "receiverId": userId,
        "content": content
      });
    } catch (_) {}
  }

  // ================= SOCKET =================

  void _handleSocket(dynamic data) {
    if (_myId == null) return;

    if (data["type"] == "NEW_MESSAGE") {
      final msg = data["data"];
      final sender = msg["senderId"];
      final receiver = msg["receiverId"];

      final chatUser =
          sender == _myId ? receiver : sender;

      _conversationCache[chatUser] ??= [];

      final updated =
          List<dynamic>.from(_conversationCache[chatUser]!);

      if (!updated.any((m) => m["id"] == msg["id"])) {
        updated.add(msg);
        _conversationCache[chatUser] = updated;
        _emit(chatUser);
      }
    }

    if (data["type"] == "MESSAGES_READ") {
      final userId = data["userId"];

      if (userId != null &&
          _conversationCache.containsKey(userId)) {
        final updated =
            List<dynamic>.from(_conversationCache[userId]!);

        for (int i = 0; i < updated.length; i++) {
          if (updated[i]["senderId"] == _myId) {
            updated[i] = {
              ...updated[i],
              "isRead": true,
            };
          }
        }

        _conversationCache[userId] = updated;
        _emit(userId);
      }
    }
  }

  // ================= EMIT =================

  void _emit(String userId) {
    _streams[userId] ??=
        StreamController.broadcast();

    _streams[userId]!
        .add(List.from(_conversationCache[userId]!));
  }

  // ================= DISPOSE =================

  void dispose() {
    _socketSub?.cancel();

    for (var s in _streams.values) {
      s.close();
    }

    _streams.clear();
  }
}
