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
import 'package:app_project/providers/voice_world_provider.dart'; // new: Fix #5
import 'package:app_project/providers/user_locations_provider.dart';

class GlobalSocketManager with WidgetsBindingObserver {

  GlobalSocketManager._internal();

  static final GlobalSocketManager _instance =
      GlobalSocketManager._internal();

  static GlobalSocketManager get instance => _instance;

  WebSocketService? _socketService;
  StreamSubscription? _socketSubscription;
  String? _userId;

  bool _initialized        = false;
  bool _observerAdded      = false;
  bool _incomingScreenOpen = false;
  bool _isReconnecting     = false;

  Timer? _reconnectTimer;

  // ── Streams — unchanged ───────────────────────────────
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  // ── Init — unchanged ──────────────────────────────────
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

        // ── ONLINE_USERS_LIST — unchanged ────────────────
        if (type == "ONLINE_USERS_LIST") {
          final users = List<String>.from(event["users"] ?? []);
          globalProviderContainer
              .read(onlineUsersProvider.notifier)
              .state = users.toSet();
          _messageController.add(event);
        }

        // ── USER_ONLINE — unchanged ──────────────────────
        else if (type == "USER_ONLINE") {
          final uid = event["userId"]?.toString();
          if (uid != null) {
            final n = globalProviderContainer.read(onlineUsersProvider.notifier);
            n.state = { ...n.state, uid };
          }
          _messageController.add(event);
        }

        // ── USER_OFFLINE — unchanged ─────────────────────
        else if (type == "USER_OFFLINE") {
          final uid = event["userId"]?.toString();
          if (uid != null) {
            final n       = globalProviderContainer.read(onlineUsersProvider.notifier);
            final updated = { ...n.state };
            updated.remove(uid);
            n.state = updated;
          }
          _messageController.add(event);
        }

        // ── INCOMING_CALL — unchanged ────────────────────
        else if (type == "INCOMING_CALL") {
          _handleIncomingCall(event);
        }

        // ── NEW_MESSAGE — unchanged ──────────────────────
        else if (type == "NEW_MESSAGE") {

          final data          = event["data"];
          final senderId      = data["senderId"]?.toString();
          final currentUserId = _userId?.toString();

          if (senderId == currentUserId) {
            _messageController.add(event);
            return;
          }

          final receiverId = data["receiverId"]?.toString();

          if (senderId != currentUserId && senderId != null) {
            UnreadCounterService.increment(senderId);
          }

          ChatController.instance.handleNewMessage(data);

          final notifier = globalProviderContainer.read(messagesProvider.notifier);
          final current  = { ...notifier.state };

          final chatId = senderId == currentUserId
              ? receiverId ?? ""
              : senderId   ?? "";

          if (chatId.isNotEmpty) {
            final oldMessages   = current[chatId] ?? [];
            final alreadyExists = oldMessages.any((m) => m["id"] == data["id"]);

            if (!alreadyExists) {
              final updatedMessages = List<dynamic>.from([...oldMessages, data]);
              if (updatedMessages.length > 100) updatedMessages.removeAt(0);
              current[chatId] = updatedMessages;
              notifier.state  = current;
            }

            final recentNotifier = globalProviderContainer.read(recentChatsProvider.notifier);
            final recentChats    = List<dynamic>.from(recentNotifier.state);

            final existingIndex = recentChats.indexWhere(
              (c) => c["user"]?["id"] == chatId,
            );

            if (existingIndex != -1) {
              final old = recentChats.removeAt(existingIndex);
              recentChats.insert(0, {
                ...old,
                "lastMessage": data["content"] ??
                    (data["type"] == "image" ? "📷 Image" : ""),
                "time":        DateTime.now().toIso8601String(),
                "unreadCount": senderId != currentUserId
                    ? ((old["unreadCount"] ?? 0) + 1)
                    : (old["unreadCount"] ?? 0),
              });
            } else {
              recentChats.insert(0, {
                "user": {
                  "id":    chatId,
                  "phone": data["senderPhone"] ??
                           data["receiverPhone"] ?? "Unknown",
                },
                "lastMessage": data["content"] ??
                    (data["type"] == "image" ? "📷 Image" : ""),
                "time":        DateTime.now().toIso8601String(),
                "unreadCount": senderId != currentUserId ? 1 : 0,
              });
            }

            if (recentChats.length > 200) {
              recentChats.removeRange(200, recentChats.length);
            }

            recentNotifier.state = recentChats;
          }

          _messageController.add(event);
        }

        // new: Fix #5 — VOICE_PROMOTED WebSocket handler
        //
        // Pehle: Ye event "else" block mein jaata tha
        //        _messageController mein forward hota tha
        //        Lekin koi sun nahi raha tha → promotion kabhi work nahi karta tha
        //
        // Ab: VoiceRoomNotifier directly notify karo
        //     try-catch: Provider disposed ho toh silently skip karo
        //     groupId match: Sirf current room ka promotion handle karo
        //
        else if (type == "VOICE_PROMOTED") {
          final groupId = event["groupId"]?.toString();

          debugPrint("🎙️ VOICE_PROMOTED received — groupId: $groupId");

          try {
            // VoiceRoomNotifier read karo — autoDispose hai
            // Room screen open hai toh available hoga
            // Band hai toh ProviderException → catch block
            final roomNotifier = globalProviderContainer
                .read(voiceRoomProvider.notifier);
            roomNotifier.handleWebSocketPromotion(groupId); // new: Fix #5
          } catch (_) {
            // Room screen open nahi hai — promotion ignore karo
            // Normal case — no action needed
          }

          _messageController.add(event);
        }

        // ── USER_LOCATION_UPDATE — real-time location ────
        else if (type == "USER_LOCATION_UPDATE") {
          final uid = event["userId"]?.toString();
          final lat = (event["latitude"]  as num?)?.toDouble();
          final lng = (event["longitude"] as num?)?.toDouble();

          if (uid != null && lat != null && lng != null) {
            globalProviderContainer
                .read(userLocationsProvider.notifier)
                .updateLocation(uid, lat, lng);
          }
          _messageController.add(event);
        }

        // ── Sab baaki events ─────────────────────────────
        else {
          _messageController.add(event);
        }
      },

      onError:       (e) => debugPrint("❌ Socket stream error: $e"),
      onDone:        ()  => debugPrint("⚠️ Socket stream closed"),
      cancelOnError: false,
    );

    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }

    await _socketService!.connect();

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

  // ── Incoming Call — unchanged ─────────────────────────
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
    ).then((_) => _incomingScreenOpen = false);
  }

  // ── Send — unchanged ──────────────────────────────────
  void send(Map<String, dynamic> data) => _socketService?.send(data);

  // ── Lifecycle — unchanged ─────────────────────────────
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

  // ── Disconnect — unchanged ────────────────────────────
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

  // ── Getters — unchanged ───────────────────────────────
  bool   get isConnected => _socketService?.isConnected ?? false;
  String get wsUrl       => _socketService?.wsUrl ?? "";

  // ── Dispose — unchanged ───────────────────────────────
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
