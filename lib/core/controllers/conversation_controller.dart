import 'dart:async';
import '../network/api_client.dart';
import '../socket/socket_service.dart';

class ConversationController {
  ConversationController._internal();
  static final ConversationController _instance =
      ConversationController._internal();
  static ConversationController get instance => _instance;

  final Map<String, List<dynamic>> _conversationCache = {};
  final Map<String, StreamController<List<dynamic>>> _streams = {};

  String? _myId;

  void init(String myId) {
    _myId = myId;
    SocketService.connect(myId);

    SocketService.onMessage(_handleSocket);
  }

  Stream<List<dynamic>> stream(String userId) {
    _streams[userId] ??= StreamController.broadcast();
    return _streams[userId]!.stream;
  }

  List<dynamic> getMessages(String userId) {
    return _conversationCache[userId] ?? [];
  }

  Future<void> loadMessages(String userId) async {
    if (_conversationCache.containsKey(userId)) {
      _emit(userId);
      return;
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
    _conversationCache[userId]!.add(tempMessage);
    _emit(userId);

    try {
      await ApiClient.post("/chat/send", {
        "receiverId": userId,
        "content": content
      });
    } catch (_) {}
  }

  void _handleSocket(dynamic data) {
    if (data["type"] == "NEW_MESSAGE") {
      final msg = data["data"];
      final sender = msg["senderId"];
      final receiver = msg["receiverId"];

      final chatUser =
          sender == _myId ? receiver : sender;

      _conversationCache[chatUser] ??= [];

      if (!_conversationCache[chatUser]!
          .any((m) => m["id"] == msg["id"])) {
        _conversationCache[chatUser]!.add(msg);
        _emit(chatUser);
      }
    }

    if (data["type"] == "MESSAGES_READ") {
      final by = data["by"];

      for (var entry in _conversationCache.entries) {
        entry.value
            .where((m) => m["senderId"] == _myId)
            .forEach((m) => m["isRead"] = true);

        _emit(entry.key);
      }
    }
  }

  void _emit(String userId) {
    _streams[userId] ??=
        StreamController.broadcast();

    _streams[userId]!
        .add(List.from(_conversationCache[userId]!));
  }

  void dispose() {
    for (var s in _streams.values) {
      s.close();
    }
    _streams.clear();
  }
}
