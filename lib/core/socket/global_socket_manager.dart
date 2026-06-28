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
import 'package:app_project/core/controllers/conversation_controller.dart';

import 'package:app_project/providers/online_users_provider.dart';
import 'package:app_project/providers/messages_provider.dart';
import 'package:app_project/providers/recent_chats_provider.dart';
import 'package:app_project/providers/voice_world_provider.dart'; // new: Fix #5
import 'package:app_project/core/session/user_session.dart';
import 'package:app_project/core/location/location_service.dart';
import 'package:app_project/core/network/api_client.dart';
import 'package:geolocator/geolocator.dart';

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
  bool _wasAutoDisabledByGps = false;

  Timer? _reconnectTimer;
  Timer? _gpsDebounceTimer;
  StreamSubscription<ServiceStatus>? _gpsStatusSubscription;

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

        // ✅ NEW: PENDING_MESSAGES — offline the toh missed messages
        // Backend connect hone pe push karta hai
        else if (type == "PENDING_MESSAGES") {
          final messages = List<dynamic>.from(event["data"] ?? []);

          for (final msg in messages) {
            final senderId  = msg["senderId"]?.toString();
            final chatId    = senderId == _userId
                ? msg["receiverId"]?.toString() ?? ""
                : senderId ?? "";

            if (chatId.isEmpty) continue;

            // messagesProvider update karo
            final notifier = globalProviderContainer
                .read(messagesProvider.notifier);
            final current = { ...notifier.state };
            final oldMessages   = current[chatId] ?? [];
            final alreadyExists =
                oldMessages.any((m) => m["id"] == msg["id"]);

            if (!alreadyExists) {
              final updated = List<dynamic>.from([...oldMessages, msg]);
              if (updated.length > 100) updated.removeAt(0);
              current[chatId] = updated;
              notifier.state  = current;
            }

            // ConversationController cache bhi update karo
            ChatController.instance.handleNewMessage(msg);
          }

          // recentChats refresh karo
          final recentNotifier =
              globalProviderContainer.read(recentChatsProvider.notifier);
          recentNotifier.state =
              List<dynamic>.from(recentNotifier.state);

          _messageController.add(event);
        }

        // ✅ NEW: MESSAGE_CONFIRMED — tempId ko real DB id se replace karo
        else if (type == "MESSAGE_CONFIRMED") {
          final tempId = event["tempId"]?.toString();
          final data   = event["data"] as Map<String, dynamic>?;

          if (tempId != null && data != null) {
            final senderId  = data["senderId"]?.toString();
            final receiverId = data["receiverId"]?.toString();
            final chatId    = senderId == _userId
                ? receiverId ?? ""
                : senderId   ?? "";

            if (chatId.isNotEmpty) {
              // messagesProvider mein replace karo
              final notifier = globalProviderContainer
                  .read(messagesProvider.notifier);
              final current = { ...notifier.state };
              final msgs    = List<dynamic>.from(current[chatId] ?? []);
              final idx     =
                  msgs.indexWhere((m) => m["id"]?.toString() == tempId);
              if (idx != -1) {
                msgs[idx]       = data;
                current[chatId] = msgs;
                notifier.state  = current;
              }

              // ConversationController mein bhi replace karo
              ConversationController.instance
                  .replaceTempMessage(tempId, data, chatId);
            }
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

    // ✅ NEW Fix #12 — GPS hardware on/off continuously sunte raho
    // (heat-protection, battery saver, manual toggle — sabhi cases cover)
    _listenGpsStatus();

    await _socketService!.connect();

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (_socketService?.isConnected != true && !_isReconnecting) {
          _isReconnecting = true;
          _socketService?.connect().whenComplete(() {
            _isReconnecting = false;
            // ✅ NEW: Reconnect ke baad conversations force reload
            ConversationController.instance.forceReloadAll();
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
          // ✅ NEW: Wapas aaye toh pending messages load karo
          ConversationController.instance.forceReloadAll();
        });
      }

      // ✅ NEW Fix #11 — agar location abhi ON nahi hai, silently check karo
      // ki permission Settings se manually grant toh nahi hui (dialog nahi aayega)
      _checkLocationOnResume();

    } else if (state == AppLifecycleState.paused) {
      // ✅ NEW: App background gaya — server ko turant offline batao
      // Server ko signal milega → ws.on("close") → USER_OFFLINE broadcast
      _socketService?.disconnect();
    }
  }

  Future<void> _checkLocationOnResume() async {
    if (UserSession.locationEnabled) return; // already ON — kuch nahi karna

    final granted = await LocationService.hasPermissionNow();
    if (!granted) return; // abhi bhi nahi diya — silently ignore, dialog nahi

    final result = await LocationService.updateLocationOnLogin();
    if (result == LocationUpdateResult.success) {
      UserSession.locationEnabled = true;
    }
  }

  // ✅ NEW Fix #12 — GPS hardware on/off continuously sunte raho
  void _listenGpsStatus() {
    _gpsStatusSubscription?.cancel();
    _gpsStatusSubscription =
        Geolocator.getServiceStatusStream().listen((status) {
      // ✅ Debounce — signal flicker/weather ki wajah se rapid on-off
      // ho toh turant react nahi karna, 3 second stable rehne do
      _gpsDebounceTimer?.cancel();
      _gpsDebounceTimer = Timer(const Duration(seconds: 3), () {
        _handleGpsStatusChange(status);
      });
    });
  }

  Future<void> _handleGpsStatusChange(ServiceStatus status) async {
    if (status == ServiceStatus.disabled) {
      // GPS beech mein band ho gaya — agar sharing ON thi, safely clear karo
      // taaki doosre users ko stale/wrong distance na dikhe
      if (UserSession.locationEnabled) {
        _wasAutoDisabledByGps = true;
        try {
          await ApiClient.delete("/profile/location");
        } catch (e) {
          debugPrint("📍 GPS-off auto-clear failed: $e");
        }
        UserSession.locationEnabled = false;
        debugPrint("📍 GPS band hua — location backend se clear ki");
      }
    } else if (status == ServiceStatus.enabled) {
      // GPS wapas on hua — agar isi wajah se band hui thi, dobara try karo
      if (_wasAutoDisabledByGps) {
        _wasAutoDisabledByGps = false;
        final result = await LocationService.updateLocationOnLogin();
        if (result == LocationUpdateResult.success) {
          UserSession.locationEnabled = true;
          debugPrint("📍 GPS wapas on — location dobara share ki");
        }
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

    // ✅ NEW Fix #12 — GPS listener bhi band karo
    _gpsStatusSubscription?.cancel();
    _gpsStatusSubscription = null;
    _gpsDebounceTimer?.cancel();
    _wasAutoDisabledByGps = false;

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
