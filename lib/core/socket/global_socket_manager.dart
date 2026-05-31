import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'websocket_service.dart';

import 'package:app_project/features/call/presentation/incoming_call_screen.dart';
import 'package:app_project/main.dart';
import 'package:app_project/core/riverpod/app_container.dart';

import 'package:app_project/core/chat/unread_counter_service.dart';
import 'package:app_project/core/controllers/chat_controller.dart';

import 'package:app_project/providers/online_users_provider.dart';
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

  bool _initialized    = false;
  bool _observerAdded  = false;
  bool _incomingScreenOpen = false;

  // ✅ UNCHANGED: reconnect protection flags
  bool   _isReconnecting = false;
  Timer? _reconnectTimer;

  // ================= STREAMS — ✅ UNCHANGED =================

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  // ================= INIT — ✅ UNCHANGED =================

  Future<void> init(String userId) async {

    if (_initialized && _userId == userId) return;

    _userId = userId;

    await _socketSubscription?.cancel();
    _socketSubscription = null;

    _socketService?.dispose();
    _socketService = WebSocketService(userId: userId);

    _socketSubscription = _socketService!.messages.listen(
      (event) {

        final type = event["type"];

        // ================= ONLINE — ✅ UNCHANGED =================

        if (type == "ONLINE_USERS_LIST") {

          final users = List<String>.from(event["users"] ?? []);

          final notifier = globalProviderContainer.read(
            onlineUsersProvider.notifier,
          );

          notifier.state = { ...notifier.state, ...users.toSet() };

          _messageController.add(event);
        }

        // ================= USER_ONLINE — ✅ UNCHANGED =================

        else if (type == "USER_ONLINE") {

          final userId = event["userId"]?.toString();

          if (userId != null) {
            final notifier = globalProviderContainer.read(
              onlineUsersProvider.notifier,
            );
            notifier.state = { ...notifier.state, userId };
          }

          _messageController.add(event);
        }

        // ================= USER_OFFLINE — ✅ UNCHANGED =================

        else if (type == "USER_OFFLINE") {

          final userId = event["userId"]?.toString();

          if (userId != null) {
            final notifier = globalProviderContainer.read(
              onlineUsersProvider.notifier,
            );
            final updated = { ...notifier.state };
            updated.remove(userId);
            notifier.state = updated;
          }

          _messageController.add(event);
        }

        // ================= INCOMING CALL — ✅ UNCHANGED =================

        else if (type == "INCOMING_CALL") {
          _handleIncomingCall(event);
        }

        // ================= NEW MESSAGE — FIXED =================

        else if (type == "NEW_MESSAGE") {

          final data          = event["data"];
          final senderId      = data["senderId"]?.toString();
          final currentUserId = _userId?.toString();

          // ✅ UNCHANGED: Self echo ignore karo
          if (senderId == currentUserId) {
            _messageController.add(event);
            return;
          }

          final receiverId = data["receiverId"]?.toString();

          // ✅ UNCHANGED: Unread counter
          if (senderId != currentUserId && senderId != null) {
            UnreadCounterService.increment(senderId);
          }

          // ✅ UNCHANGED: Legacy chat controller
          ChatController.instance.handleNewMessage(data);

          // ✅ UNCHANGED: Messages provider update
          final notifier = globalProviderContainer.read(
            messagesProvider.notifier,
          );

          final current = { ...notifier.state };

          final chatId = senderId == currentUserId
              ? receiverId ?? ""
              : senderId ?? "";

          if (chatId.isNotEmpty) {

            final oldMessages = current[chatId] ?? [];

            // ✅ UNCHANGED: Duplicate safe check
            final alreadyExists = oldMessages.any(
              (m) => m["id"] == data["id"],
            );

            if (!alreadyExists) {

              final updatedMessages = List<dynamic>.from([
                ...oldMessages,
                data,
              ]);

              // ✅ UNCHANGED: Keep only latest 100 messages
              if (updatedMessages.length > 100) {
                updatedMessages.removeAt(0);
              }

              current[chatId] = updatedMessages;
              notifier.state  = current;
            }

            // ================= RECENT CHATS UPDATE — FIXED =================

            final recentNotifier = globalProviderContainer.read(
              recentChatsProvider.notifier,
            );

            final recentChats = List<dynamic>.from(recentNotifier.state);

            // ✅ FIX #1: WRONG KEY BUG — sabse critical fix
            //
            // Problem: c["userId"] == chatId
            //          Backend /chat/recent response mein "userId" key exist
            //          hi nahi karti — isliye indexWhere hamesha -1 return
            //          karta tha — existing chat kabhi update nahi hoti thi,
            //          hamesha nayi duplicate entry insert ho jaati thi upar
            //
            // Backend actual response format:
            // { user: { id: "abc123", phone: "..." }, lastMessage: "...", time: "..." }
            //
            // Fix: c["user"]["id"] == chatId — ye sahi key hai
            //
            final existingIndex = recentChats.indexWhere(
              // ❌ PEHLE: (c) => c["userId"] == chatId
              (c) => c["user"]?["id"] == chatId, // ✅ FIXED
            );

            if (existingIndex != -1) {

              // ✅ UNCHANGED: Existing chat ko upar le aao, content update karo
              final old = recentChats.removeAt(existingIndex);

              recentChats.insert(0, {
                ...old,
                "lastMessage": data["content"] ??
                    (data["type"] == "image" ? "📷 Image" : ""),

                // ✅ FIX #2: "updatedAt" → "time"
                //
                // Problem: Hum "updatedAt" set kar rahe the lekin
                //          chat_card.dart "time" key read karta hai
                //          Isliye chat card mein time update nahi dikhti thi
                //
                "time": DateTime.now().toIso8601String(), // ✅ FIXED

                "unreadCount": senderId != currentUserId
                    ? ((old["unreadCount"] ?? 0) + 1)
                    : (old["unreadCount"] ?? 0),
              });

            } else {

              // ✅ UNCHANGED: Naya chat insert karo — format same
              recentChats.insert(0, {
                "user": {
                  "id": chatId,
                  "phone": data["senderPhone"] ??
                      data["receiverPhone"] ??
                      "Unknown",
                },
                "lastMessage": data["content"] ??
                    (data["type"] == "image" ? "📷 Image" : ""),
                "time": DateTime.now().toIso8601String(),
                "unreadCount": senderId != currentUserId ? 1 : 0,
              });
            }

            // ✅ UNCHANGED: Keep latest 200 chats
            if (recentChats.length > 200) {
              recentChats.removeRange(200, recentChats.length);
            }

            recentNotifier.state = recentChats;
          }

          _messageController.add(event);
        }

        // ================= UNREAD UPDATE — ✅ UNCHANGED =================

        // Baaki saare events seedhe messageController mein jaayenge
        // Voice world events, notifications, etc. — sab handle ho jaayenge
        else {
          _messageController.add(event);
        }
      },

      onError: (e) {
        debugPrint("❌ Socket stream error: $e");
      },

      onDone: () {
        debugPrint("⚠️ Socket stream closed");
      },

      cancelOnError: false,
    );

    // ================= OBSERVER — ✅ UNCHANGED =================

    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }

    // ================= CONNECT — ✅ UNCHANGED =================

    await _socketService!.connect();

    // ================= WATCHDOG — ✅ UNCHANGED =================

    _reconnectTimer?.cancel();

    _reconnectTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (_socketService?.isConnected != true && !_isReconnecting) {
          _isReconnecting = true;
          _socketService?.connect().whenComplete(() {
            _isReconnecting = false;
          });
        }
      },
    );

    _initialized = true;
  }

  // ================= INCOMING CALL — ✅ UNCHANGED =================

  void _handleIncomingCall(Map<String, dynamic> data) {

    if (_incomingScreenOpen) return;

    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    _incomingScreenOpen = true;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          sessionId: data["sessionId"],
          callerId:  data["callerId"],
          callType:  data["callType"],
        ),
      ),
    ).then((_) {
      _incomingScreenOpen = false;
    });
  }

  // ================= SEND — ✅ UNCHANGED =================

  void send(Map<String, dynamic> data) {
    _socketService?.send(data);
  }

  // ================= LIFECYCLE — ✅ UNCHANGED =================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.resumed) {
      if (_socketService?.isConnected != true && !_isReconnecting) {
        _isReconnecting = true;
        _socketService?.connect().whenComplete(() {
          _isReconnecting = false;
        });
      }
    }
  }

  // ================= DISCONNECT — ✅ UNCHANGED =================

  Future<void> disconnect() async {

    await _socketSubscription?.cancel();
    _socketSubscription = null;

    _socketService?.disconnect();
    _socketService = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _initialized = false;
    _userId      = null;

    globalProviderContainer
        .read(onlineUsersProvider.notifier)
        .state = {};
  }

  // ================= GETTERS — ✅ UNCHANGED =================

  bool   get isConnected => _socketService?.isConnected ?? false;
  String get wsUrl       => _socketService?.wsUrl ?? "";

  // ================= DISPOSE — ✅ UNCHANGED =================

  void dispose() {

    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }

    _socketSubscription?.cancel();
    _socketSubscription = null;

    _socketService?.dispose();
    _socketService = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _messageController.close();

    globalProviderContainer
        .read(onlineUsersProvider.notifier)
        .state = {};

    _initialized = false;
    _userId      = null;
  }
}
