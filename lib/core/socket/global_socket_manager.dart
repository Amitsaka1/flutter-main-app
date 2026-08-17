import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'centrifugo_service.dart';
import 'package:app_project/core/riverpod/app_container.dart';

import 'package:app_project/core/chat/unread_counter_service.dart';
import 'package:app_project/core/controllers/chat_controller.dart';
import 'package:app_project/core/controllers/conversation_controller.dart';

import 'package:app_project/providers/online_users_provider.dart';
import 'package:app_project/providers/messages_provider.dart';
import 'package:app_project/providers/recent_chats_provider.dart';
import 'package:app_project/core/session/user_session.dart';
import 'package:app_project/core/location/location_service.dart';
import 'package:app_project/core/network/api_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class GlobalSocketManager with WidgetsBindingObserver {

  GlobalSocketManager._internal();

  static final GlobalSocketManager _instance =
      GlobalSocketManager._internal();

  static GlobalSocketManager get instance => _instance;

  CentrifugoService? _socketService;
  StreamSubscription? _socketSubscription;
  String? _userId;

  bool _initialized        = false;
  bool _observerAdded      = false;
  bool _isReconnecting     = false;
  bool _wasAutoDisabledByGps = false;

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _gpsDebounceTimer;
  StreamSubscription<ServiceStatus>? _gpsStatusSubscription;

  // 6.8.1 — Connectivity listener fields
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  Timer?  _connectivityDebounce;
  int     _reconnectFailCount = 0;
  
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
    _socketService = CentrifugoService(userId: userId);

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

        // ── USER_ONLINE — FIX Bug 1: pehle .remove(uid) tha, ulta ho raha
        // tha (online hote hi user set se hat jata tha, isliye green
        // dot/"Online" text kabhi sahi nahi dikhta tha) ─────────────
        if (type == "USER_ONLINE") {
          final uid = event["userId"]?.toString();
          if (uid != null) {
            final n       = globalProviderContainer.read(onlineUsersProvider.notifier);
            final updated = { ...n.state };
            updated.add(uid);
            n.state = updated;
          }
          _messageController.add(event);
        }

        // ── USER_OFFLINE — FIX Bug 2: ye event pehle kahin bhi handle
        // nahi hota tha, backend se aata tha aur silently drop ho jata
        // tha — isliye "last seen" kabhi realtime update nahi hota tha ──
        if (type == "USER_OFFLINE") {
          final uid = event["userId"]?.toString();
          if (uid != null) {
            final n       = globalProviderContainer.read(onlineUsersProvider.notifier);
            final updated = { ...n.state };
            updated.remove(uid);
            n.state = updated;
          }
          _messageController.add(event);
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

          final activeChat   = ChatController.instance.activeChatUserId;
          final isActiveChat = activeChat == senderId;

          if (senderId != currentUserId && senderId != null) {
            if (!isActiveChat) {
              UnreadCounterService.increment(senderId);
            } else {
              ConversationController.instance.markConversationRead(senderId);
            }
          }
          
          if (!isActiveChat) {
            ChatController.instance.handleNewMessage(data);
          }

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
                "unreadCount": (senderId != currentUserId && !isActiveChat)
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
                "unreadCount": (senderId != currentUserId && !isActiveChat) ? 1 : 0,
              });
            }

            if (recentChats.length > 200) {
              recentChats.removeRange(200, recentChats.length);
            }

            recentNotifier.state = recentChats;
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

        // ── UNREAD_UPDATE — backend mark-read pe count=0 bhejta hai ──
        else if (type == "UNREAD_UPDATE") {
          final count = event["count"] ?? 0;
          if (count == 0) {
            // Mark-read hua — UnreadCounterService reset karo
            // Kaunsa chat? activeChat ya senderId se nahi pata chalta
            // isliye _refreshRecentChats se fresh state lo
            _refreshRecentChats();
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

    // ✅ FIX Bug A — connect hote hi backend ko batao "main online hoon"
    // (pehle ye kabhi call hi nahi hoti thi, isliye USER_ONLINE
    // event kabhi fire nahi hota tha)
    _notifyOnConnect();

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _onConnectionCheckTick(),
    );

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 40),
      (_) => _sendHeartbeat(),
    );

    // 6.8.2 — Connectivity listener start karo
    _startConnectivityListener();

    _initialized = true;
  }

  // ✅ NEW — Bug A fix: connect hote hi backend ko notify karo
  Future<void> _notifyOnConnect() async {
    try {
      await ApiClient.get('/realtime/on-connect');
    } catch (_) {
      // ignore — agla heartbeat retry karega
    }
  }

  // ── Send — unchanged ──────────────────────────────────
  void send(Map<String, dynamic> data) => _socketService?.send(data);

  // ── Nearby (Find feature) ──────────────────────────────
  Future<void> subscribeToNearby(List<String> channels) async {
    await _socketService?.subscribeToNearbyChannels(channels);
  }

  Future<void> unsubscribeFromNearby() async {
    await _socketService?.unsubscribeFromNearbyChannels();
  }

  // ── Lifecycle — unchanged ─────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 6.7.1 — Resume pe pehle internet check karo
      Connectivity().checkConnectivity().then((result) {
        if (result != ConnectivityResult.none) {
          // 6.7.4 — Same helper — internet ON flow same hai
          _reconnectAndSync();
        }
        // No internet → set already cleared tha connectivity listener se (6.4.4)
      });
      _checkLocationOnResume();

    } else if (state == AppLifecycleState.paused) {
      // 6.6.1 — Background → disconnect + backend ko explicitly batao
      _socketService?.disconnect();
      ApiClient.post('/realtime/disconnect', {}).catchError((_) {});
      // 6.6.2 — Set CLEAR MAT KARO — stale data rakho
    }
  }

  // Point 2/3/4/5/6 Fix: Recent chats API se fresh unreadCount lo
  // In-memory state stale ho sakti hai — server always correct hai
  Future<void> _refreshRecentChats() async {
    try {
      final response = await ApiClient.get("/chat/recent");
      if (response["success"] == true) {
        final data = List<dynamic>.from(response["data"]);
        globalProviderContainer
            .read(recentChatsProvider.notifier)
            .state = data;
      }
    } catch (_) {
      // Network nahi — stale state rehne do, user pull-to-refresh karega
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

    // 6.8.3 — Connectivity listener cancel karo
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _connectivityDebounce?.cancel();
    _connectivityDebounce = null;
    _reconnectFailCount = 0;

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

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    // 6.8.3 — Connectivity cleanup in dispose bhi
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _connectivityDebounce?.cancel();
    _connectivityDebounce = null;

    _messageController.close();

    globalProviderContainer
        .read(onlineUsersProvider.notifier)
        .state = {};

    _initialized = false;
    _userId      = null;
  }

  // ─────────────────────────────────────────────────────
  // 6.8 — Connectivity Listener
  // ─────────────────────────────────────────────────────
  void _startConnectivityListener() {
    _connectivitySub?.cancel();

    // 6.8.4 — App start pe bhi ek baar initial state check
    Connectivity().checkConnectivity().then((result) {
      if (result == ConnectivityResult.none) {
        globalProviderContainer
            .read(onlineUsersProvider.notifier)
            .state = {};
      }
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      // 6.8.5 + 7.7 — Debounce 2s — WiFi↔Mobile Data switch pe false triggers
      _connectivityDebounce?.cancel();
      _connectivityDebounce = Timer(const Duration(seconds: 2), () {
        _handleConnectivityChange(result);
      });
    });
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      debugPrint("📡 Internet OFF — online set clear");
      globalProviderContainer
          .read(onlineUsersProvider.notifier)
          .state = {};
      // 6.4.6 — Reconnect timer pause karo — futile attempts band
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      // Server ko signal karo ki ye user offline ho gaya
      // TCP FIN/RST server tak pahuchega → ws.on("close") fire hoga
      // Agar nahi pahuncha (internet truly dead) → heartbeat 10s mein detect karega
      _socketService?.disconnect();
    } else {
      // 6.5 — Internet ON → exact sequence: reconnect → bulk fetch
      debugPrint("📡 Internet ON — reconnect + sync");
      _reconnectAndSync();
      // Timer restart karo agar band tha
      _reconnectTimer ??= Timer.periodic(
        const Duration(seconds: 10),
        (_) => _onReconnectTick(),
      );
    }
  }

  // ─────────────────────────────────────────────────────
  // 6.9 — Resync Helper (7.6 — sirf ek call hogi)
  //
  // NOTE: Ye function khud WebSocket reconnect NAHI karta —
  // Centrifugo client apna reconnect internally khud hi
  // exponential backoff se handle karta hai (CentrifugoService
  // ke andar). Ye function sirf ye check karta hai ki abhi
  // connected hai kya, aur agar hai toh app-level data resync
  // karta hai (recent chats, online status, unread).
  // ─────────────────────────────────────────────────────
  Future<void> _resyncIfConnected() async {
    if (_isReconnecting) return; // 7.6 — concurrent calls prevent
    _isReconnecting = true;
    try {
      if (_socketService?.isConnected == true) {
        _reconnectFailCount = 0;
        ConversationController.instance.forceReloadAll();
        await _refreshRecentChats();
        await _fetchOnlineStatusForRecentChats();

        final activeChat = ChatController.instance.activeChatUserId;
        if (activeChat != null) {
          ConversationController.instance.markConversationRead(activeChat);
        }
      }
    } catch (_) {
      // ignore — agla tick retry karega
    } finally {
      _isReconnecting = false;
    }
  }

  // ─────────────────────────────────────────────────────
  // Connection Check Tick — failure tracking (6.10)
  //
  // NOTE: Ye Centrifugo ko reconnect nahi karta (wo khud karta
  // hai) — sirf har 10s check karta hai ki connected hai kya.
  // Agar 3 baar (30s) tak disconnected dikha toh stale online
  // dots UI se clear kar deta hai.
  // ─────────────────────────────────────────────────────
  void _onConnectionCheckTick() {
    if (_isReconnecting) return;

    if (_socketService?.isConnected == true) {
      _isReconnecting = true;
      _resyncIfConnected().whenComplete(() => _isReconnecting = false);
    } else {
      _reconnectFailCount++;
      if (_reconnectFailCount >= 3) {
        debugPrint("⚠️ 3 ticks disconnected — stale dots clear");
        globalProviderContainer
            .read(onlineUsersProvider.notifier)
            .state = {};
      }
    }
  }

  // ─────────────────────────────────────────────────────
  // 6.5 — Bulk Online Status Fetch (5.6.1 endpoint use karo)
  // ─────────────────────────────────────────────────────
  Future<void> _fetchOnlineStatusForRecentChats() async {
    try {
      final recentChats = globalProviderContainer.read(recentChatsProvider);
      final userIds = recentChats
          .map<String?>((c) => c["user"]?["id"]?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .take(100) // 5.6.5 — max 100
          .toList();

      if (userIds.isEmpty) return;

      final response = await ApiClient.get(
        "/users/online-status",
        queryParams: {"ids": userIds.join(",")},
      );

      if (response["success"] == true) {
        final statusMap = response["data"] as Map<String, dynamic>? ?? {};
        final current = Set<String>.from(
          globalProviderContainer.read(onlineUsersProvider),
        );

        for (final entry in statusMap.entries) {
          final isOnline =
              (entry.value as Map<String, dynamic>?)?["isOnline"] == true;
          if (isOnline) {
            current.add(entry.key);
          } else {
            current.remove(entry.key);
          }
        }

        globalProviderContainer
            .read(onlineUsersProvider.notifier)
            .state = current;
      }
    } catch (_) {
      // ignore — stale state rehne do
    }
  }

  // ─────────────────────────────────────────────────────
  // Heartbeat — presence TTL refresh karta hai (~40s)
  // ─────────────────────────────────────────────────────
  Future<void> _sendHeartbeat() async {
    if (_socketService?.isConnected != true) return;
    try {
      await ApiClient.post('/realtime/heartbeat', {});
    } catch (_) {
      // ignore — agla tick retry karega
    }
  }
}
