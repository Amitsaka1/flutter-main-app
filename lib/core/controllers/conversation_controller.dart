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

  // ✅ UNCHANGED: track loaded conversations
  final Set<String> _loadedConversations = {};

  // ✅ FIX #2 (NEW): Pagination state per conversation
  // Problem: Backend ab { data, hasMore, nextCursor } bhejta hai
  //          Flutter sirf response["data"] padhta tha — baaki ignore
  //          User scroll up kare toh purane messages load nahi hote the
  // Fix: Har conversation ka cursor aur hasMore track karo
  final Map<String, String?> _nextCursor  = {};
  final Map<String, bool>    _hasMore     = {};
  final Map<String, bool>    _loadingMore = {}; // Double load prevent karo

  final Map<String, Timer?> _markReadDebounce = {};

  void markConversationRead(String userId) {
    _markReadDebounce[userId]?.cancel();
    _markReadDebounce[userId] = Timer(const Duration(milliseconds: 400), () async {
      try {
        await ApiClient.post("/chat/mark-read", { "senderId": userId });
      } catch (_) {}
    });
  }

  // ================= INIT — ✅ UNCHANGED =================

  void init(String myId) {
    if (_socketInitialized && _myId == myId) return;

    _myId = myId;

    _socketSub?.cancel();

    _socketSub = GlobalSocketManager.instance.messages
        .listen(_handleSocket);

    _socketInitialized = true;
  }

  // ================= STREAM — ✅ UNCHANGED =================

  Stream<List<dynamic>> stream(String userId) {
    _streams[userId] ??= StreamController.broadcast();
    return _streams[userId]!.stream;
  }

  List<dynamic> getMessages(String userId) {
    return List.from(_conversationCache[userId] ?? []);
  }

  // ✅ UNCHANGED: Cache check
  bool hasMessages(String userId) {
    return _conversationCache.containsKey(userId) &&
        _conversationCache[userId]!.isNotEmpty;
  }

  // ✅ FIX #2 (NEW): Scroll up pe aur messages hain ya nahi
  bool canLoadMore(String userId) => _hasMore[userId] ?? false;

  // ================= LOAD — FIXED =================

  Future<void> loadMessages(String userId) async {

    // ✅ UNCHANGED: Cache se turant dikhao
    if (_conversationCache.containsKey(userId)) {
      if (!_loadedConversations.contains(userId)) {
        _emit(userId);
      }
    }

    // ✅ UNCHANGED: Already loaded — skip API
    if (_loadedConversations.contains(userId)) {
      _emit(userId);
      return;
    }

    try {

      final response = await ApiClient.get("/chat/messages/$userId");

      if (response["success"] == true) {

        _conversationCache[userId] = List.from(response["data"]);

        // ✅ FIX #2: Pagination state save karo
        // Problem: Pehle ye lines nahi thin — cursor hamesha null tha
        // Fix: Backend se aayi pagination info store karo
        _nextCursor[userId] = response["nextCursor"];     // ✅ FIXED
        _hasMore[userId]    = response["hasMore"] ?? false; // ✅ FIXED

        _loadedConversations.add(userId);

        _emit(userId);
      }

    } catch (_) {}
  }

  // ✅ FIX #2 (NEW): Load more — scroll up pe call karo
  //
  // Problem: Pehle ye function exist hi nahi karta tha
  //          User scroll up karta tha — kuch nahi hota tha
  //
  // Fix: cursor-based pagination — backend se agle 30 messages lo
  //      Existing messages ke UPAR prepend karo (purane messages upar hote hain)
  //
  // Flutter mein use karo:
  //   if (ConversationController.instance.canLoadMore(userId)) {
  //     await ConversationController.instance.loadMore(userId);
  //   }
  //
  Future<void> loadMore(String userId) async {

    // ✅ Already loading hai ya aur messages nahi hain — skip
    if (_loadingMore[userId] == true) return;
    if (_hasMore[userId] != true)     return;

    final cursor = _nextCursor[userId];
    if (cursor == null) return;

    _loadingMore[userId] = true;

    try {

      final response = await ApiClient.get(
        "/chat/messages/$userId",
        queryParams: { "cursor": cursor, "limit": "30" },
      );

      if (response["success"] == true) {

        final older = List.from(response["data"]);

        // ✅ Purane messages UPAR lagao — naye neeche hain
        final existing = _conversationCache[userId] ?? [];
        _conversationCache[userId] = [...older, ...existing];

        // ✅ Agla cursor update karo
        _nextCursor[userId] = response["nextCursor"];
        _hasMore[userId]    = response["hasMore"] ?? false;

        _emit(userId);
      }

    } catch (_) {
    } finally {
      _loadingMore[userId] = false;
    }
  }

  // ================= SEND — ✅ UNCHANGED =================

  // modify: Fix #19 — createdAt add + real message return karo
  //
  // Problem 1: createdAt missing tha — sort comparator naye message ko
  //            "sabse purana" maan leta tha, TOP pe jump karta tha
  // Problem 2: Server response ignore hota tha — real id/createdAt
  //            kabhi temp message ko replace nahi karte the
  //
  Future<Map<String, dynamic>?> sendMessage(
    String userId,
    String content,
  ) async {

    if (_myId == null) return null;

    final tempMessage = {
      "id":         DateTime.now().millisecondsSinceEpoch.toString(),
      "senderId":   _myId,
      "receiverId": userId,
      "content":    content,
      "isRead":     false,
      "createdAt":  DateTime.now().toIso8601String(), // new: Fix #19
    };

    if (_loadedConversations.contains(userId)) {
      // provider handles realtime UI
    } else {

      _conversationCache[userId] ??= [];

      final updated = List<dynamic>.from(_conversationCache[userId]!);
      updated.add(tempMessage);

      if (updated.length > 100) updated.removeAt(0);

      _conversationCache[userId] = updated;
      _emit(userId);
    }

    try {
      final response = await ApiClient.post("/chat/send", {
        "receiverId": userId,
        "content":    content,
      });

      // new: Fix #19 — real message return karo
      if (response["success"] == true) {
        return response["data"] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ================= SOCKET — FIXED =================

  void _handleSocket(dynamic data) {

    if (_myId == null) return;

    // ================= NEW MESSAGE — ✅ UNCHANGED =================

    if (data["type"] == "NEW_MESSAGE") {

      final msg      = data["data"];
      final sender   = msg["senderId"];
      final receiver = msg["receiverId"];
      final chatUser = sender == _myId ? receiver : sender;

      _conversationCache[chatUser] ??= [];

      final updated = List<dynamic>.from(_conversationCache[chatUser]!);

      // ✅ UNCHANGED: Duplicate prevention
      if (!updated.any((m) => m["id"] == msg["id"])) {

        updated.add(msg);

        // ✅ UNCHANGED: Keep latest 100
        if (updated.length > 100) updated.removeAt(0);

        _conversationCache[chatUser] = updated;
        _loadedConversations.add(chatUser);

        _emit(chatUser);
      }
    }

    // ================= MESSAGES READ — FIXED =================

    if (data["type"] == "MESSAGES_READ") {

      // ✅ FIX #1: "userId" → "by"
      //
      // Problem: Backend bhejta hai: { type: "MESSAGES_READ", by: "userId123" }
      //          Flutter padhta tha:  data["userId"]  ← ALWAYS NULL
      //          Isliye double tick marks kabhi nahi aate the
      //
      // Fix: data["by"] — ye sahi field naam hai
      //
      final userId = data["by"]; // ❌ PEHLE: data["userId"]  ✅ AB: data["by"]

      if (userId != null &&
          _conversationCache.containsKey(userId)) {

        final updated = List<dynamic>.from(_conversationCache[userId]!);

        // ✅ UNCHANGED: Saare apne messages ko isRead: true karo
        for (int i = 0; i < updated.length; i++) {
          if (updated[i]["senderId"] == _myId) {
            updated[i] = { ...updated[i], "isRead": true };
          }
        }

        _conversationCache[userId] = updated;
        _emit(userId);
      }
    }
  }

  // ================= EMIT — ✅ UNCHANGED =================

  void _emit(String userId) {
    _streams[userId] ??= StreamController.broadcast();
    _streams[userId]!.add(List.from(_conversationCache[userId]!));
  }

  // ================= TELEGRAM STYLE RELOAD — NEW =================

  /// Reconnect ke baad call karo — fresh data fetch hoga
  /// Cache clear nahi hota — stale data instantly dikhta rehega
  /// API call tab hogi jab user conversation open karega
  void forceReloadAll() {
    _loadedConversations.clear();
  }

  /// Sirf ek conversation ko force reload karo
  void forceReloadConversation(String userId) {
    _loadedConversations.remove(userId);
  }

  /// MESSAGE_CONFIRMED ke liye — tempId ko real DB id se replace karo
  void replaceTempMessage(
      String tempId, Map<String, dynamic> realMessage, String chatId) {
    final messages = _conversationCache[chatId];
    if (messages == null) return;

    final updated = List<dynamic>.from(messages);
    final idx     = updated.indexWhere((m) => m["id"]?.toString() == tempId);
    if (idx != -1) {
      updated[idx]             = realMessage;
      _conversationCache[chatId] = updated;
      _emit(chatId);
    }
  }

  // ================= DISPOSE — FIXED =================

  void dispose() {

    _socketSub?.cancel();

    for (var s in _streams.values) s.close();

    _streams.clear();
    _conversationCache.clear();
    _loadedConversations.clear();

    // ✅ FIX #2: Naye pagination maps bhi clear karo
    _nextCursor.clear();  // ✅ FIXED
    _hasMore.clear();     // ✅ FIXED
    _loadingMore.clear(); // ✅ FIXED
  }
}
