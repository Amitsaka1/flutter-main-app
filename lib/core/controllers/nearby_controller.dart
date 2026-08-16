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

  double radiusKm = 5.0;
  double? latitude;
  double? longitude;
  List<String> channels = [];
  List<Map<String, dynamic>> messages = [];

  /// App/Dashboard open hote hi -- disk se purana "Official Group" state
  /// load karo (agar pehle kabhi Find dabaya tha), taaki tile turant dikhe.
  Future<void> loadFromDisk() async {
    final saved = await NearbyGroupState.load();
    if (saved != null) {
      hasGroup = true;
      radiusKm = saved.radiusKm;
      latitude = saved.latitude;
      longitude = saved.longitude;
      channels = saved.channels;
      notifyListeners();
    }
  }

  /// "Find" (ya "change") dabane pe -- fresh GPS + naye radius se
  /// /nearby/find call karta hai, Official Group state update karta hai.
  Future<NearbyLocationResult> findWithRadius(double newRadiusKm) async {
    loading = true;
    notifyListeners();

    final (locResult, pos) = await NearbyService.getFreshLocation();
    if (locResult != NearbyLocationResult.success || pos == null) {
      loading = false;
      notifyListeners();
      return locResult;
    }

    try {
      final result = await NearbyService.find(
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusKm: newRadiusKm,
      );

      radiusKm = newRadiusKm;
      latitude = pos.latitude;
      longitude = pos.longitude;
      channels = result.channels;
      messages = result.messages;
      hasGroup = true;

      await NearbyGroupState.save(
        radiusKm: radiusKm,
        latitude: pos.latitude,
        longitude: pos.longitude,
        channels: channels,
      );

      loading = false;
      notifyListeners();
      return NearbyLocationResult.success;
    } catch (e) {
      loading = false;
      notifyListeners();
      return NearbyLocationResult.failed;
    }
  }

  /// Chat screen ke andar live-push se aaya naya message add karta hai.
  void addIncomingMessage(Map<String, dynamic> msg) {
    final alreadyExists = messages.any((m) => m["id"] == msg["id"]);
    if (alreadyExists) return;
    messages = [...messages, msg];
    if (messages.length > 100) messages.removeAt(0);
    notifyListeners();
  }
}
