import 'package:flutter/foundation.dart';
import 'package:app_project/core/location/nearby_service.dart';
import 'package:app_project/core/session/nearby_group_state.dart';

/// "Official Group" ka single source of truth -- Dashboard tile aur group
/// chat screen dono isi controller ko share karte hain, taaki "Find" dabane
/// pe dono jagah turant sync ho jaye (koi duplicate state na ho).
///
/// NOTE: Ye sirf history + channel-names hold karta hai. Live Centrifugo
/// subscribe/unsubscribe **chat screen khud karta hai** (jaisa design kiya
/// tha -- "group chat screen se bahar niklo, live feed se disconnect",
/// persistent membership nahi hai).
class NearbyController extends ChangeNotifier {
  NearbyController._internal();
  static final NearbyController instance = NearbyController._internal();

  bool hasGroup = false;
  bool loading = false;
  bool locationEnabled = false;

  double radiusKm = 5.0;
  List<String> channels = [];
  List<Map<String, dynamic>> messages = [];

  /// App/Dashboard open hote hi -- disk se purana "Official Group" state
  /// load karo (agar pehle kabhi Find dabaya tha), taaki tile turant dikhe.
  Future<void> loadFromDisk() async {
    final saved = await NearbyGroupState.load();
    if (saved != null) {
      hasGroup = true;
      radiusKm = saved.radiusKm;
      channels = saved.channels;
      notifyListeners();
    }
  }

  /// "Your Location" button (radius popup) -- fresh GPS lekar Profile me
  /// save karta hai. Har baar call hone pe naya fresh fetch hota hai.
  Future<NearbyLocationResult> updateMyLocation() async {
    loading = true;
    notifyListeners();

    final result = await NearbyService.updateMyLocation();
    if (result == NearbyLocationResult.success) locationEnabled = true;

    loading = false;
    notifyListeners();
    return result;
  }

  /// "Find" (ya "change") dabane pe -- naye radius se /nearby/find call
  /// karta hai (location backend khud Profile se leta hai), Official
  /// Group state update karta hai.
  Future<NearbyLocationResult> findWithRadius(double newRadiusKm) async {
    loading = true;
    notifyListeners();

    try {
      final result = await NearbyService.find(radiusKm: newRadiusKm);

      radiusKm = newRadiusKm;
      channels = result.channels;
      messages = result.messages;
      hasGroup = true;

      await NearbyGroupState.save(
        radiusKm: radiusKm,
        channels: channels,
      );

      loading = false;
      notifyListeners();
      return NearbyLocationResult.success;
    } catch (e) {
      loading = false;
      notifyListeners();
      // Backend "Your Location is not set" bhi isi raste error karta hai
      // -- caller ko exact message dikhana ho toh e.toString() use karo.
      return NearbyLocationResult.failed;
    }
  }

  /// Chat screen ke andar live-push se aaya naya message add karta hai.
  /// Distance jaan-boojh kar broadcast payload me nahi aata (privacy) --
  /// isliye add karte hi background me alag se fetch karke patch karte
  /// hain (2-step: message turant dikhega, badge 1 second baad aayega).
  void addIncomingMessage(Map<String, dynamic> msg) {
    final alreadyExists = messages.any((m) => m["id"] == msg["id"]);
    if (alreadyExists) return;
    messages = [...messages, msg];
    if (messages.length > 100) messages.removeAt(0);
    notifyListeners();

    final id = msg["id"]?.toString();
    if (id != null && msg["distance"] == null) {
      _fetchDistanceFor(id);
    }
  }

  Future<void> _fetchDistanceFor(String messageId) async {
    final distance = await NearbyService.getDistance(messageId);
    if (distance == null) return;
    final idx = messages.indexWhere((m) => m["id"] == messageId);
    if (idx == -1) return;
    final updated = [...messages];
    updated[idx] = {...updated[idx], "distance": distance};
    messages = updated;
    notifyListeners();
  }

  /// Optimistic tempId wale message ko real (server-confirmed) data se
  /// replace karta hai -- taaki apna hi bheja hua message Centrifugo echo
  /// se dobara na jud jaye (duplicate bubble na bane).
  void replaceMessage(String tempId, Map<String, dynamic> realData) {
    final idx = messages.indexWhere((m) => m["id"] == tempId);
    if (idx == -1) {
      addIncomingMessage(realData);
      return;
    }
    final updated = [...messages];
    updated[idx] = realData;
    messages = updated;
    notifyListeners();
  }
}
