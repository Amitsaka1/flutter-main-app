import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:app_project/core/network/api_client.dart';

// ✅ FIX #1: Hardcoded URL hata ke config se lo
//
// Problem: "wss://momo-qd13.onrender.com/ws" seedha code mein tha
//          Server change karo toh naya APK build + Play Store upload zaroori
//
// Fix: Ek jagah se URL control karo — sirf ye ek line badloge production mein
//
// HOW TO USE: ApiClient mein baseUrl pehle se hai
//             Wahan se ws URL bhi nikal lo — ek jagah se sab control
//
class WebSocketConfig {
  // ✅ ApiClient.baseUrl se derive karo — "https://" → "wss://"
  // Agar ApiClient.baseUrl = "https://momo-qd13.onrender.com"
  // Toh wsUrl = "wss://momo-qd13.onrender.com/ws"
  static String get wsUrl =>
      ApiClient.baseUrl
          .replaceFirst("https://", "wss://")
          .replaceFirst("http://",  "ws://")
      + "/ws";
}

class WebSocketService {
  final String userId;

  // ✅ FIX #1: Hardcoded string hata diya — config se aata hai
  // Ab sirf ApiClient.baseUrl badlo, WebSocket URL automatically update hogi
  String get wsUrl => WebSocketConfig.wsUrl;

  WebSocketChannel? _channel;

  bool _connected    = false;
  bool _connecting   = false;
  bool _manualDisconnect = false;

  int _reconnectAttempt = 0;

  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // ✅ FIX #2: Connection state stream — UI ko pata chale connected hai ya nahi
  //
  // Problem: Flutter UI ko nahi pata tha socket connected hai ya disconnect
  //          User chat kar raha hota tha — messages silently deliver nahi hote
  //
  // Fix: isConnectedStream se UI real-time status dikha sakta hai
  //      "Connecting..." ya "Reconnecting..." banner show karo chat screen pe
  //
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionState => _connectionStateController.stream;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages      => _messageController.stream;
  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;

  WebSocketService({required this.userId});

  // ================= CONNECT =================

  Future<void> connect() async {
    if (_connected || _connecting) return;

    _connecting = true;
    _manualDisconnect = false;

    try {
      print("⚡ Connecting WebSocket for user: $userId → $wsUrl");

      final token = await ApiClient.getToken();

      // ✅ UNCHANGED: Same connection logic
      _channel = WebSocketChannel.connect(
        Uri.parse("$wsUrl?token=$token"),
      );

      // ✅ FIX #3: _connected = true BAAD mein set karo, PEHLE nahi
      //
      // Problem: Pehle _connected = true set ho jaata tha BEFORE stream.listen
      //          Agar stream.listen throw kare toh _connected true tha
      //          lekin koi listener nahi tha — silent failure
      //          send() sochta connected hai, messages void mein jaate the
      //
      // Fix: Pehle timers aur listeners set karo, TAB _connected = true
      //
      _reconnectAttempt = 0;

      // ✅ UNCHANGED: Ping timer same logic
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) {
          if (_connected && _channel != null) {
            try {
              _channel!.sink.add('ping');
            } catch (_) {}
          }
        },
      );

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);

            // ✅ UNCHANGED: Notification aur message routing same hai
            if (decoded["type"] == "NEW_NOTIFICATION") {
              _notificationController.add(decoded);
              return;
            }

            _messageController.add(decoded);
          } catch (e) {
            print("Socket decode error: $e");
          }
        },
        onDone:  _handleDisconnect,
        onError: (error) {
          print("Socket error: $error");
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      // ✅ FIX #3: Ab set karo — listener setup ho gaya hai
      _connected  = true;
      _connecting = false;

      // ✅ FIX #2: UI ko notify karo — connected ho gaye
      _connectionStateController.add(true);

      print("🔥 SOCKET CONNECTED for user: $userId");

    } catch (e) {
      print("❌ WebSocket connection failed: $e");

      _connecting = false;
      _connected  = false;

      // ✅ FIX #2: UI ko notify karo — connection fail hua
      _connectionStateController.add(false);

      _scheduleReconnect();
    }
  }

  // ================= DISCONNECT — ✅ UNCHANGED =================

  void disconnect() {
    print("🔴 Manual disconnect for user: $userId");

    _manualDisconnect = true;

    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    _channel?.sink.close();
    _channel = null;

    _connected = false;
  }

  // ================= HANDLE DISCONNECT =================

  void _handleDisconnect() {
    print("❌ SOCKET DISCONNECTED for user: $userId");

    _channel   = null;
    _connected = false;

    _pingTimer?.cancel();

    // ✅ FIX #2: UI ko notify karo — disconnect hua
    _connectionStateController.add(false);

    // ✅ UNCHANGED: Manual disconnect nahi tha toh reconnect karo
    if (!_manualDisconnect) {
      _scheduleReconnect();
    }
  }

  // ================= AUTO RECONNECT — FIXED =================

  void _scheduleReconnect() {
    if (_manualDisconnect) return;

    _reconnectAttempt++;

    // ✅ FIX #4: Linear → Exponential Backoff + Random Jitter
    //
    // Problem: Pehle linear tha — attempt × 2 seconds
    //          Attempt 1: 2s, Attempt 2: 4s, Attempt 3: 6s ...
    //          Ye slow hai — real exponential nahi tha
    //
    //          Aur SABSE BADI PROBLEM: Jitter nahi tha
    //          Server restart ho → 1 lakh users EXACT same time pe reconnect
    //          = "Thundering Herd" = server turant crash
    //
    // Fix: 2^attempt seconds + random jitter (0-1s extra random wait)
    //      Attempt 1: 2s + jitter    (~2.0-3.0s)
    //      Attempt 2: 4s + jitter    (~4.0-5.0s)
    //      Attempt 3: 8s + jitter    (~8.0-9.0s)
    //      Attempt 4: 16s + jitter   (~16-17s)
    //      Attempt 5+: 30s + jitter  (capped at 30s)
    //
    //      Jitter se 1 lakh users alag alag time pe reconnect karenge
    //      Server pe load evenly spread ho jaata hai
    //
    final exponentialDelay = pow(2, _reconnectAttempt).toInt(); // 2, 4, 8, 16...
    final jitter           = Random().nextDouble();              // 0.0 to 1.0 seconds
    final delaySeconds     = (exponentialDelay + jitter).clamp(1.0, 30.0);

    print(
      "⏳ Reconnecting in ${delaySeconds.toStringAsFixed(1)}s "
      "(Attempt $_reconnectAttempt, exponential + jitter)"
    );

    _reconnectTimer?.cancel();

    _reconnectTimer = Timer(
      Duration(milliseconds: (delaySeconds * 1000).toInt()),
      () => connect(),
    );
  }

  // ================= SEND — ✅ UNCHANGED =================

  void send(Map<String, dynamic> data) {
    if (_connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (e) {
        print("Send error: $e");
      }
    } else {
      print("⚠ Cannot send. Socket not connected.");
    }
  }

  // ================= STATE — ✅ UNCHANGED =================

  bool get isConnected => _connected;

  // ================= DISPOSE — FIXED =================

  void dispose() {
    print("🧹 Disposing WebSocket for user: $userId");

    _manualDisconnect = true;

    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    _channel?.sink.close();
    _channel = null;

    _connected = false;

    // ✅ FIX #2: connectionStateController bhi close karo — memory leak nahi hogi
    _connectionStateController.close();
    _messageController.close();
    _notificationController.close();
  }
}
