import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'websocket_service.dart';
import 'package:app_project/features/call/presentation/incoming_call_screen.dart';
import 'package:app_project/main.dart';

class GlobalSocketManager with WidgetsBindingObserver {
  GlobalSocketManager._internal();
  static final GlobalSocketManager _instance =
      GlobalSocketManager._internal();
  static GlobalSocketManager get instance => _instance;

  WebSocketService? _socketService;
  StreamSubscription? _socketSubscription;

  String? _userId;
  bool _initialized = false;
  bool _foreground = true;
  bool _observerAdded = false;

  bool _incomingScreenOpen = false;

  final StreamController<Map<String, dynamic>>
      _messageController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages =>
      _messageController.stream;

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

      // 🔥 Incoming Call
      if (type == "INCOMING_CALL") {
        _handleIncomingCall(event);
      }

      // 🔥 Seat map update
      if (type == "SEAT_MAP_UPDATE") {
        _seatMapController.add(event);
      }

      // 🔥 Room closed
      if (type == "ROOM_CLOSED") {
        _roomClosedController.add(null);
      }

      _messageController.add(event);
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

  void onSeatMapUpdate(
    Function(Map<String, dynamic>) callback,
  ) {
    _seatMapController.stream.listen(callback);
  }

  void onRoomClosed(
    VoidCallback callback,
  ) {
    _roomClosedController.stream.listen((_) {
      callback();
    });
  }

  // ================= INCOMING CALL =================

  void _handleIncomingCall(Map<String, dynamic> data) {
    if (_incomingScreenOpen) return;

    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    _incomingScreenOpen = true;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          sessionId: data["sessionId"],
          callerId: data["callerId"],
          callType: data["callType"],
        ),
      ),
    ).then((_) {
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
    // 🔥 Do NOT disconnect socket on background
    // Keep persistent connection for real-time features

    if (state == AppLifecycleState.resumed) {
      if (!_socketService!.isConnected) {
        _socketService!.connect();
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
  }

  bool get isConnected =>
      _socketService?.isConnected ?? false;

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

    _initialized = false;
    _userId = null;
  }
}
