import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;
import 'package:app_project/core/network/api_client.dart';

enum NearbyLocationResult {
  success,
  gpsOff,
  permissionDenied,
  permissionPermanentlyDenied,
  locationUnavailable,
  failed,
}

class NearbyFindResult {
  final List<Map<String, dynamic>> messages;
  final List<String> channels;
  final double radiusKm;

  NearbyFindResult({
    required this.messages,
    required this.channels,
    required this.radiusKm,
  });
}

/// "Find" feature ka service layer -- fresh GPS lena (LocationService jaisa
/// hi robust pattern: GPS-on dialog, permission_handler, 3-try fallback),
/// phir /nearby/find aur /nearby/send call karna.
class NearbyService {
  // ================= FRESH LOCATION (Find dabane pe) =================

  /// Har baar "Find" dabane pe fresh GPS location leta hai -- jaisa decide
  /// kiya tha (cached/stale location use nahi karte).
  static Future<(NearbyLocationResult, Position?)> getFreshLocation() async {
    try {
      if (kIsWeb) {
        try {
          final pos = await Geolocator.getCurrentPosition()
              .timeout(const Duration(seconds: 15));
          return (NearbyLocationResult.success, pos);
        } catch (_) {
          return (NearbyLocationResult.failed, null);
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await loc.Location().requestService();
        if (!serviceEnabled) {
          return (NearbyLocationResult.gpsOff, null);
        }
      }

      PermissionStatus status = await Permission.locationWhenInUse.status;

      if (status.isPermanentlyDenied) {
        return (NearbyLocationResult.permissionPermanentlyDenied, null);
      }

      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
      }

      if (status.isPermanentlyDenied) {
        return (NearbyLocationResult.permissionPermanentlyDenied, null);
      }

      if (!status.isGranted) {
        return (NearbyLocationResult.permissionDenied, null);
      }

      final position = await _getLocation();
      if (position == null) {
        return (NearbyLocationResult.locationUnavailable, null);
      }

      return (NearbyLocationResult.success, position);
    } catch (e) {
      debugPrint("📍 Nearby location fetch failed: $e");
      return (NearbyLocationResult.failed, null);
    }
  }

  static Future<Position?> _getLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      debugPrint("📍 Nearby Try 1 failed");
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 20));
    } catch (_) {
      debugPrint("📍 Nearby Try 2 failed");
    }

    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final age = DateTime.now().difference(last.timestamp);
        if (age.inMinutes < 5) return last; // Find ke liye bahut fresh chahiye
      }
    } catch (_) {
      debugPrint("📍 Nearby Try 3 failed");
    }

    return null;
  }

  // ================= YOUR LOCATION (profile-saved GPS) =================

  /// "Your Location" button (radius popup ke andar) -- fresh GPS leta hai
  /// (getFreshLocation() wala hi robust flow -- GPS-on check, permission,
  /// 3-try fallback) aur backend Profile me save karta hai. Find/Send ab
  /// isi saved location ko use karte hain, alag se lat/lng nahi bhejte.
  static Future<NearbyLocationResult> updateMyLocation() async {
    final (result, pos) = await getFreshLocation();
    if (result != NearbyLocationResult.success || pos == null) return result;

    try {
      final res = await ApiClient.patch("/profile/location", {
        "latitude": pos.latitude,
        "longitude": pos.longitude,
      });
      if (res["success"] != true) return NearbyLocationResult.failed;
      return NearbyLocationResult.success;
    } catch (e) {
      debugPrint("📍 updateMyLocation save failed: $e");
      return NearbyLocationResult.failed;
    }
  }

  // ================= FIND =================

  /// User-selected radiusKm ke saath /nearby/find call karta hai -- backend
  /// khud "Your Location" (Profile me saved) use karta hai, isliye yahan
  /// lat/lng bhejne ki zaroorat nahi. History (mutual-range filtered,
  /// formatted distance ke saath) + geohash channels (live subscribe ke
  /// liye) dono return hote hain.
  static Future<NearbyFindResult> find({required double radiusKm}) async {
    final res = await ApiClient.post("/nearby/find", {
      "radiusKm": radiusKm,
    });

    if (res["success"] != true) {
      throw Exception(res["message"] ?? "Nearby find failed");
    }

    final data = res["data"] as Map<String, dynamic>;
    return NearbyFindResult(
      messages: List<Map<String, dynamic>>.from(data["messages"] ?? []),
      channels: List<String>.from(data["channels"] ?? []),
      radiusKm: radiusKm,
    );
  }

  // ================= SEND =================

  /// Group me message bhejna -- backend "Your Location" (Profile) + us
  /// waqt ka selected radius khud tag karta hai.
  static Future<Map<String, dynamic>> send({
    required String text,
    required double radiusKm,
  }) async {
    final res = await ApiClient.post("/nearby/send", {
      "text": text,
      "radiusKm": radiusKm,
    });

    if (res["success"] != true) {
      throw Exception(res["message"] ?? "Message send failed");
    }

    return res["data"] as Map<String, dynamic>;
  }

  // ================= LIVE MESSAGE DISTANCE =================

  /// Live-push se turant aaye message ka distance-badge sahi karne ke liye
  /// -- privacy-safe (sirf formatted "X km" string aata hai, coordinates
  /// kabhi nahi).
  static Future<String?> getDistance(String messageId) async {
    try {
      final res = await ApiClient.get("/nearby/distance/$messageId");
      if (res["success"] != true) return null;
      return (res["data"] as Map<String, dynamic>)["distance"]?.toString();
    } catch (e) {
      debugPrint("📍 getDistance failed: $e");
      return null;
    }
  }
}
