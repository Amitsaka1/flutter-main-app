import 'dart:async';
import '../network/api_client.dart';
import '../socket/global_socket_manager.dart';

class ConversationController {
  ConversationController._internal();

  static final ConversationController _instance =
      ConversationController._internal();

  static ConversationController get instance => _instance;

  final Map<String, List<dynamic>> _conversationCache = {};

  final Map<String, StreamController<List<dynamic>>>
      _streams = {};

  String? _myId;

  bool _socketInitialized = false;

  StreamSubscription? _socketSub;

  /// 🔥 track loaded conversations
  final Set<String> _loadedConversations = {};

  // ================= INIT =================

  void init(String myId) {
    if (_socketInitialized && _myId == myId) return;

    _myId = myId;

    _socketSub?.cancel();

    _socketSub =
        GlobalSocketManager.instance.messages
            .listen(_handleSocket);

    _socketInitialized = true;
  }

  // ================= STREAM =================

  Stream<List<dynamic>> stream(String userId) {
    _streams[userId] ??=
        StreamController.broadcast();

    return _streams[userId]!.stream;
  }

  List<dynamic> getMessages(String userId) {
    return List.from(
      _conversationCache[userId] ?? [],
    );
  }

  /// 🔥 check cache
  bool hasMessages(String userId) {
    return _conversationCache.containsKey(userId) &&
        _conversationCache[userId]!.isNotEmpty;
  }

  // ================= LOAD =================

  Future<void> loadMessages(String userId) async {

    /// 🔥 INSTANT SHOW (CACHE)
    if (_conversationCache.containsKey(userId)) {

      /// 🔥 avoid unnecessary emit
      if (!_loadedConversations.contains(userId)) {
        _emit(userId);
      }
    }

    /// 🔥 ALREADY LOADED → SKIP API
    if (_loadedConversations.contains(userId)) {

      _emit(userId);
      
      return;
    }

    try {

      final response =
          await ApiClient.get(
        "/chat/messages/$userId",
      );

      if (response["success"] == true) {

        _conversationCache[userId] =
            List.from(response["data"]);

        _loadedConversations.add(userId);

        /// 🔥 mark read
        ApiClient.post("/chat/mark-read", {
          "senderId": userId,
        });

        _emit(userId);
      }

    } catch (_) {}
  }

  // ================= SEND =================

  Future<void> sendMessage(
    String userId,
    String content,
  ) async {

    if (_myId == null) return;

    final tempMessage = {
      "id":
          DateTime.now()
              .millisecondsSinceEpoch
              .toString(),

      "senderId": _myId,
      "receiverId": userId,
      "content": content,
      "isRead": false,
    };

    /// 🔥 Skip local append if
    /// Riverpod already handling UI
    if (_loadedConversations.contains(userId)) {

      // provider handles realtime UI

    } else {

      _conversationCache[userId] ??= [];

      final updated =
          List<dynamic>.from(
        _conversationCache[userId]!,
      );

      updated.add(tempMessage);

      /// 🔥 keep latest 100
      if (updated.length > 100) {
        updated.removeAt(0);
      }

      _conversationCache[userId] = updated;

      _emit(userId);
    }

    try {

      await ApiClient.post("/chat/send", {
        "receiverId": userId,
        "content": content,
      });

    } catch (_) {}
  }

  // ================= SOCKET =================

  void _handleSocket(dynamic data) {

  if (_myId == null) return;

  // ================= NEW MESSAGE =================

  if (data["type"] == "NEW_MESSAGE") {

    final msg = data["data"];

    final sender = msg["senderId"];

    final receiver = msg["receiverId"];

    final chatUser =
        sender == _myId
            ? receiver
            : sender;

    _conversationCache[chatUser] ??= [];

    final updated =
        List<dynamic>.from(
      _conversationCache[chatUser]!,
    );

    /// 🔥 DUPLICATE PREVENTION
    if (!updated.any(
      (m) => m["id"] == msg["id"],
    )) {

      updated.add(msg);

      /// 🔥 keep latest 100
      if (updated.length > 100) {
        updated.removeAt(0);
      }

      _conversationCache[chatUser] =
          updated;

      _loadedConversations.add(chatUser);

      /// 🔥 ALWAYS EMIT
      _emit(chatUser);
    }
  }

    // ================= MESSAGES READ =================

    if (data["type"] == "MESSAGES_READ") {

      final userId = data["userId"];

      if (userId != null &&
          _conversationCache.containsKey(
            userId,
          )) {

        final updated =
            List<dynamic>.from(
          _conversationCache[userId]!,
        );

        for (
          int i = 0;
          i < updated.length;
          i++
        ) {

          if (updated[i]["senderId"] ==
              _myId) {

            updated[i] = {
              ...updated[i],
              "isRead": true,
            };
          }
        }

        _conversationCache[userId] =
            updated;

        _emit(userId);
      }
    }
  }

  // ================= EMIT =================

  void _emit(String userId) {

    _streams[userId] ??=
        StreamController.broadcast();

    _streams[userId]!.add(
      List.from(
        _conversationCache[userId]!,
      ),
    );
  }

  // ================= DISPOSE =================

  void dispose() {

    _socketSub?.cancel();

    for (var s in _streams.values) {
      s.close();
    }

    _streams.clear();

    _conversationCache.clear();

    _loadedConversations.clear();
  }
}
