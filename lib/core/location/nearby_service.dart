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
  final double latitude;
  final double longitude;
  final double radiusKm;

  NearbyFindResult({
    required this.messages,
    required this.channels,
    required this.latitude,
    required this.longitude,
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

  // ================= FIND =================

  /// Fresh lat/lng + user-selected radiusKm ke saath /nearby/find call
  /// karta hai -- history (exact Haversine) + geohash channels (live
  /// subscribe ke liye) dono return hote hain.
  static Future<NearbyFindResult> find({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final res = await ApiClient.post("/nearby/find", {
      "latitude": latitude,
      "longitude": longitude,
      "radiusKm": radiusKm,
    });

    if (res["success"] != true) {
      throw Exception(res["message"] ?? "Nearby find failed");
    }

    final data = res["data"] as Map<String, dynamic>;
    return NearbyFindResult(
      messages: List<Map<String, dynamic>>.from(data["messages"] ?? []),
      channels: List<String>.from(data["channels"] ?? []),
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  // ================= SEND =================

  /// Group me message bhejna -- sender ki current location + us waqt ka
  /// selected radius tag hoti hai (jaisa design kiya tha).
  static Future<Map<String, dynamic>> send({
    required String text,
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final res = await ApiClient.post("/nearby/send", {
      "text": text,
      "latitude": latitude,
      "longitude": longitude,
      "radiusKm": radiusKm,
    });

    if (res["success"] != true) {
      throw Exception(res["message"] ?? "Message send failed");
    }

    return res["data"] as Map<String, dynamic>;
  }
}
