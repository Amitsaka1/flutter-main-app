import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ NEW
import 'websocket_service.dart';
import 'package:app_project/features/call/presentation/incoming_call_screen.dart';
import 'package:app_project/main.dart';
import 'package:app_project/core/chat/unread_counter_service.dart';
import 'package:app_project/core/controllers/chat_controller.dart';
import 'package:app_project/providers/online_users_provider.dart'; // ✅ NEW
import 'package:app_project/providers/messages_provider.dart';
import 'package:app_project/providers/recent_chats_provider.dart';

class GlobalSocketManager with WidgetsBindingObserver {
  GlobalSocketManager._internal();
  static final GlobalSocketManager _instance =
      GlobalSocketManager._internal();
  static GlobalSocketManager get instance => _instance;

  WebSocketService? _socketService;
  StreamSubscription? _socketSubscription;

  String? _userId;
  bool _initialized = false;
  bool _observerAdded = false;

  bool _incomingScreenOpen = false;

  /// ✅ Riverpod container (NEW)
  final ProviderContainer _container = ProviderContainer();

  final StreamController<Map<String, dynamic>>
      _messageController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages =>
      _messageController.stream;

  Stream<Map<String, dynamic>> get seatStream =>
      _seatMapController.stream;

  // ================= ROOM STREAMS =================

  final StreamController<Map<String, dynamic>>
      _seatMapController = StreamController.broadcast();

  final StreamController<void>
      _roomClosedController = StreamController.broadcast();

  // ================= INIT =================

  Future<void> init(String userId) async {
    if (_initialized && _userId == userId) return;

    _userId = userId;

    await _socketSubscription?.cancel();
    _socketSubscription = null;

    _socketService?.dispose();

    _socketService = WebSocketService(userId: userId);

    _socketSubscription =
        _socketService!.messages.listen((event) {

      final type = event["type"];

      /// ===============================
      /// 🔥 ONLINE STATUS (UPDATED)
      /// ===============================
      if (type == "USER_ONLINE") {
        final userId = event["userId"]?.toString();
        if (userId != null) {

          final notifier =
              _container.read(onlineUsersProvider.notifier);
          notifier.state = {...notifier.state, userId};
        }
        _messageController.add(event);
      }

      else if (type == "USER_OFFLINE") {
        final userId = event["userId"]?.toString();
        if (userId != null) {

          final notifier =
              _container.read(onlineUsersProvider.notifier);

          final updated = {...notifier.state};
          updated.remove(userId);
          notifier.state = updated;
        }
        _messageController.add(event);
      }

      // 🔥 Incoming Call
      else if (type == "INCOMING_CALL") {
        _handleIncomingCall(event);
      }

      // 🔥 Seat map update
      else if (type == "SEAT_MAP_UPDATE") {
        _seatMapController.add(event);
      }

      // 🔥 Room closed / kicked
      else if (type == "ROOM_CLOSED" ||
          type == "ROOM_KICKED") {
        _roomClosedController.add(null);
      }

      // 🔥 Speaker demoted
      else if (type == "DEMOTED_TO_LISTENER") {
        _messageController.add(event);
      }

      // 🔥 NEW MESSAGE
      else if (type == "NEW_MESSAGE") {

      final data = event["data"];

      final senderId =
          data["senderId"]?.toString();

      final receiverId =
          data["receiverId"]?.toString();

      final currentUserId = _userId?.toString();

      /// 🔥 unread
      if (senderId != currentUserId &&
          senderId != null) {
        UnreadCounterService.increment(senderId);
      }

      /// 🔥 OLD SYSTEM (KEEP SAFE)
      ChatController.instance
          .handleNewMessage(data);

      /// 🔥 NEW RIVERPOD MESSAGE SYSTEM
      final notifier =
          _container.read(messagesProvider.notifier);
    
      final current =
           {...notifier.state};

      /// determine chat partner
      String chatId = senderId == currentUserId
          ? receiverId ?? ""
          : senderId ?? "";

      if (chatId.isNotEmpty) {

        final oldMessages =
            current[chatId] ?? [];

        /// 🔥 DUPLICATE SAFE APPEND
        final alreadyExists = oldMessages.any(
          (m) => m["id"] == data["id"],
        );

        if (!alreadyExists) {

          current[chatId] = [
            ...oldMessages,
            data,
          ];

        notifier.state = current;
        }

        /// 🔥 RECENT CHATS UPDATE
        final recentNotifier =
            _container.read(recentChatsProvider.notifier);

        final recentChats =
            List<dynamic>.from(recentNotifier.state);

        final existingIndex = recentChats.indexWhere(
           (c) => c["userId"] == chatId,
        );

        if (existingIndex != -1) {

          final old =
              recentChats.removeAt(existingIndex);

          recentChats.insert(0, {
            ...old,
            "lastMessage": data["content"],
            "updatedAt":
                DateTime.now().toIso8601String(),

            /// unread increase only for receiver
            "unreadCount":
                senderId != currentUserId
                    ? ((old["unreadCount"] ?? 0) + 1)
                    : (old["unreadCount"] ?? 0),
          });
        } else {

          /// 🔥 FULL SAFE NEW CHAT OBJECT
          recentChats.insert(0, {
             "userId": chatId,

             "user": {
              "id": chatId,
               "phone":
                   data["senderPhone"] ??
                   data["receiverPhone"] ??
                  "Unknown",
             },

            "lastMessage": data["content"],

            "updatedAt":
                DateTime.now().toIso8601String(),

            "unreadCount":
                senderId != currentUserId ? 1 : 0,
          });
        }      
    });

    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }

    await _socketService!.connect();

    _initialized = true;
  }

  // ================= ROOM SOCKET =================

  void joinRoom(String roomId) {
    send({
      "type": "JOIN_ROOM_SOCKET",
      "roomId": roomId,
    });
  }

  void leaveRoom(String roomId) {
    send({
      "type": "LEAVE_ROOM_SOCKET",
      "roomId": roomId,
    });
  }

  StreamSubscription onSeatMapUpdate(
    Function(Map<String, dynamic>) callback,
  ) {
    return _seatMapController.stream.listen(callback);
  }

  StreamSubscription onRoomClosed(
    VoidCallback callback,
  ) {
    return _roomClosedController.stream.listen((_) {
      callback();
    });
  }

  // ================= INCOMING CALL =================

  void _handleIncomingCall(Map<String, dynamic> data) {
    if (_incomingScreenOpen) return;

    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    _incomingScreenOpen = true;

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          sessionId: data["sessionId"],
          callerId: data["callerId"],
          callType: data["callType"],
        ),
      ),
    )
        .then((_) {
      _incomingScreenOpen = false;
    });
  }

  // ================= SEND =================

  void send(Map<String, dynamic> data) {
    _socketService?.send(data);
  }

  // ================= APP LIFECYCLE =================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_socketService?.isConnected != true) {
        _socketService?.connect();
      }
    }
  }

  // ================= DISCONNECT =================

  Future<void> disconnect() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;

    _socketService?.disconnect();
    _socketService = null;

    _initialized = false;
    _userId = null;

    // 🔥 Provider reset
    _container.read(onlineUsersProvider.notifier).state = {};
  }

  bool get isConnected =>
      _socketService?.isConnected ?? false;

  String get wsUrl => _socketService?.wsUrl ?? "";

  // ================= DISPOSE =================

  void dispose() {
    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }

    _socketSubscription?.cancel();
    _socketSubscription = null;

    _socketService?.dispose();
    _socketService = null;

    _messageController.close();
    _seatMapController.close();
    _roomClosedController.close();

    _container.read(onlineUsersProvider.notifier).state = {};

    _initialized = false;
    _userId = null;
  }
}
