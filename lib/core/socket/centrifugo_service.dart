import 'dart:async';
import 'dart:convert';
import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:app_project/core/network/api_client.dart';
import 'package:app_project/core/config/environment.dart';

// ✅ CENTRIFUGO MIGRATION — raw `ws` (web_socket_channel) hata ke Centrifugo use
//
// Channel design (backend isi contract ko match karega):
//   - personal:user#<userId>  → sirf is user ke liye events
//     (NEW_MESSAGE, INCOMING_CALL, VOICE_PROMOTED, PENDING_MESSAGES, NEW_PROFILE...)
//     Centrifugo ka built-in "#" user-limited channel — subscribe token
//     ki zaroorat nahi, connection token (sub claim) se hi verify hota hai.
//   - broadcast:presence      → sab authenticated users ke liye
//     (USER_ONLINE, USER_OFFLINE, ADMIN_ALERT, ONLINE_USERS_LIST)
//
// Connection token: backend endpoint POST /realtime/connect-token se aata hai
//   (existing JWT auth se protected), response shape: { success: true, token: "..." }
class CentrifugoChannels {
  static String personal(String userId) => 'personal:user#$userId';
  static const String presence = 'broadcast:presence';
}

class CentrifugoService {
  final String userId;

  // ✅ SAME NAME as before (wsUrl) — GlobalSocketManager isko reference karta hai
  String get wsUrl => Environment.centrifugoUrl;

  centrifuge.Client? _client;
  centrifuge.Subscription? _personalSub;
  centrifuge.Subscription? _presenceSub;

  // "Find" feature -- dynamic geohash-cell channels. Naya radius/location
  // select hote hi purane replace ho jate hain (naye Subscribe karte
  // pehle purane unsubscribe).
  final Map<String, centrifuge.Subscription> _nearbySubs = {};
  final Map<String, StreamSubscription> _nearbyPubSubs = {};

  StreamSubscription? _connectedSub;
  StreamSubscription? _disconnectedSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _personalPubSub;
  StreamSubscription? _presencePubSub;

  bool _connected = false;

  // ✅ SAME public streams as purane WebSocketService — global_socket_manager.dart
  // aur consumers ko koi farak nahi padega
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionState => _connectionStateController.stream;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages      => _messageController.stream;
  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;

  CentrifugoService({required this.userId});

  // ================= CONNECT =================

  Future<void> connect() async {
    // ✅ Guard: GlobalSocketManager har reconnect-tick pe connect() call karta
    // hai — Centrifugo client khud reconnect/backoff sambhalta hai, isliye
    // ek hi client banao, dobara mat banao.
    if (_client != null) return;

    try {
      print("⚡ Connecting Centrifugo for user: $userId → $wsUrl");

      final client = centrifuge.createClient(
        wsUrl,
        centrifuge.ClientConfig(
          getToken: (centrifuge.ConnectionTokenEvent event) async {
            final response = await ApiClient.post('/realtime/connect-token', {});
            if (response["success"] == true && response["token"] != null) {
              return response["token"] as String;
            }
            throw Exception("Centrifugo connect-token fetch failed");
          },
        ),
      );

      _client = client;

      _connectedSub = client.connected.listen((_) {
        print("🔥 CENTRIFUGO CONNECTED for user: $userId");
        _connected = true;
        _connectionStateController.add(true);
      });

      _disconnectedSub = client.disconnected.listen((_) {
        print("❌ CENTRIFUGO DISCONNECTED for user: $userId");
        _connected = false;
        _connectionStateController.add(false);
      });

      _errorSub = client.error.listen((event) {
        print("Centrifugo error: $event");
      });

      // Personal channel
      _personalSub = client.newSubscription(CentrifugoChannels.personal(userId));
      _personalPubSub = _personalSub!.publication.listen((event) {
        _routeIncoming(event.data);
      });

      // Broadcast/presence channel
      _presenceSub = client.newSubscription(CentrifugoChannels.presence);
      _presencePubSub = _presenceSub!.publication.listen((event) {
        _routeIncoming(event.data);
      });

      // ✅ Official Centrifugo SDK pattern: subscribe() pehle, connect() baad mein
      await _personalSub!.subscribe();
      await _presenceSub!.subscribe();
      await client.connect();
    } catch (e) {
      print("❌ Centrifugo connection failed: $e");
      _connected = false;
      _connectionStateController.add(false);
      // Manual reconnect timer ki zaroorat nahi — Centrifugo client khud
      // exponential backoff + jitter se reconnect/resubscribe karta hai.
    }
  }

  void _routeIncoming(List<int> data) {
    try {
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;

      // ✅ UNCHANGED routing logic — purane WebSocketService jaisa hi
      if (decoded["type"] == "NEW_NOTIFICATION") {
        _notificationController.add(decoded);
        return;
      }

      _messageController.add(decoded);
    } catch (e) {
      print("Centrifugo decode error: $e");
    }
  }

  // ================= NEARBY (dynamic channels) =================

  /// "Find" dabane pe naye radius/location ke geohash channels
  /// subscribe karta hai -- purane automatically unsubscribe ho jate
  /// hain pehle (koi stale channel leak nahi hota).
  Future<void> subscribeToNearbyChannels(List<String> channels) async {
    if (_client == null) return;
    await unsubscribeFromNearbyChannels();

    for (final channel in channels) {
      final sub = _client!.newSubscription(channel);
      final pubSub = sub.publication.listen((event) => _routeIncoming(event.data));
      _nearbySubs[channel] = sub;
      _nearbyPubSubs[channel] = pubSub;
      await sub.subscribe();
    }
  }

  /// Group chat screen se bahar niklo -- live feed se disconnect
  /// (persistent membership nahi, jaisa design kiya tha). Connection
  /// khud zinda rehta hai, sirf ye channels chhodte hain.
  Future<void> unsubscribeFromNearbyChannels() async {
    for (final sub in _nearbySubs.values) {
      await sub.unsubscribe();
    }
    for (final pubSub in _nearbyPubSubs.values) {
      await pubSub.cancel();
    }
    _nearbySubs.clear();
    _nearbyPubSubs.clear();
  }

  // ================= DISCONNECT (temporary) =================

  void disconnect() {
    print("🔴 Manual disconnect for user: $userId");
    _client?.disconnect();
    _connected = false;
    _connectionStateController.add(false);
  }

  // ================= SEND =================
  //
  // ✅ Verified: poore Flutter app mein kahin bhi socket.send() call nahi ho
  // raha tha — saara outbound REST API (ApiClient) se jaata hai. Centrifugo
  // model mein bhi client seedha channel pe publish nahi karta (backend hi
  // publish karta hai). Ye method sirf backward-compat ke liye khali hai.
  void send(Map<String, dynamic> data) {
    print("⚠ CentrifugoService.send() called — is architecture mein outbound "
        "events REST API (ApiClient) se bhejo, socket se nahi.");
  }

  // ================= STATE =================

  bool get isConnected => _connected;

  // ================= DISPOSE (permanent) =================

  void dispose() {
    print("🧹 Disposing Centrifugo for user: $userId");

    _connectedSub?.cancel();
    _disconnectedSub?.cancel();
    _errorSub?.cancel();
    _personalPubSub?.cancel();
    _presencePubSub?.cancel();
    for (final pubSub in _nearbyPubSubs.values) {
      pubSub.cancel();
    }
    _nearbySubs.clear();
    _nearbyPubSubs.clear();

    // ⚠️ centrifuge ^0.17.0 mein Client.close() nahi hai (sirf 0.19.0+ mein
    // aaya), isliye disconnect() use karo — instance yahan se reuse nahi hoga
    _client?.disconnect();
    _client = null;

    _connected = false;

    _connectionStateController.close();
    _messageController.close();
    _notificationController.close();
  }
}
