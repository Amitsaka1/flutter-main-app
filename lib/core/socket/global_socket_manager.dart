import 'dart:async';
import 'package:flutter/widgets.dart';
import 'websocket_service.dart';

class GlobalSocketManager with WidgetsBindingObserver {
  GlobalSocketManager._internal();
  static final GlobalSocketManager _instance =
      GlobalSocketManager._internal();
  static GlobalSocketManager get instance => _instance;

  WebSocketService? _socketService;

  String? _userId;
  bool _initialized = false;
  bool _foreground = true;

  final StreamController<Map<String, dynamic>>
      _messageController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages =>
      _messageController.stream;

  // ================= INIT =================

  Future<void> init(String userId) async {
    if (_initialized && _userId == userId) return;

    _userId = userId;

    _socketService?.dispose();

    _socketService = WebSocketService(userId: userId);

    _socketService!.messages.listen((event) {
      _messageController.add(event);
    });

    WidgetsBinding.instance.addObserver(this);

    await _socketService!.connect();

    _initialized = true;
  }

  // ================= SEND =================

  void send(Map<String, dynamic> data) {
    _socketService?.send(data);
  }

  // ================= APP LIFECYCLE =================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_userId == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _foreground = false;
      _socketService?.disconnect();
    }

    if (state == AppLifecycleState.resumed) {
      if (!_foreground) {
        _foreground = true;
        _socketService?.connect();
      }
    }
  }

  // ================= DISCONNECT =================

  void disconnect() {
    _socketService?.disconnect();
    _initialized = false;
    _userId = null;
  }

  bool get isConnected =>
      _socketService?.isConnected ?? false;

  // ================= DISPOSE =================

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketService?.dispose();
    _messageController.close();
  }
}
