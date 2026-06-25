import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ ADD
import 'package:app_project/core/network/api_client.dart';
import 'package:app_project/core/session/user_session.dart';
import 'package:app_project/providers/user_locations_provider.dart';
import 'package:app_project/core/riverpod/app_container.dart';

class LocationService {

  static Future<void> updateLocationOnLogin() async {
    try {

      // Web pe alag logic
      if (kIsWeb) {
        try {
          final pos = await Geolocator.getCurrentPosition()
              .timeout(const Duration(seconds: 15));
          await _send(pos);
        } catch (_) {
          debugPrint("📍 Web location failed — skip");
        }
        return;
      }

      // GPS on hai?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("📍 GPS off — skip");
        return;
      }

      // ✅ NAYA — permission_handler use karo
      // OPPO, Vivo, Realme, Xiaomi — sabhi pe kaam karta hai
      PermissionStatus status =
          await Permission.locationWhenInUse.status;
      debugPrint("📍 Permission: $status");

      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.locationWhenInUse.request();
        debugPrint("📍 After request: $status");
      }

      if (!status.isGranted) {
        debugPrint("📍 Permission not granted — skip");
        return;
      }

      // ✅ NAYA — retry logic slow devices ke liye
      final position = await _getLocation();
      if (position == null) {
        debugPrint("📍 Location unavailable — skip");
        return;
      }

      await _send(position);

    } catch (e) {
      debugPrint("📍 Silent fail: $e");
    }
  }

  // ✅ 3 tries — fast/slow/offline sabhi devices
  static Future<Position?> _getLocation() async {

    // Try 1: Normal GPS
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      debugPrint("📍 Try 1 failed");
    }

    // Try 2: Low accuracy — Huawei/battery saver
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 20));
    } catch (_) {
      debugPrint("📍 Try 2 failed");
    }

    // Try 3: Last known location
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final age = DateTime.now().difference(last.timestamp);
        if (age.inHours < 24) return last;
      }
    } catch (_) {
      debugPrint("📍 Try 3 failed");
    }

    return null;
  }

  // Backend + Riverpod update
  static Future<void> _send(Position position) async {
    debugPrint("📍 Sending: ${position.latitude}, ${position.longitude}");

    await ApiClient.patch("/profile/location", {
      "latitude":  position.latitude,
      "longitude": position.longitude,
    });

    final myId = UserSession.getUserId();
    if (myId != null) {
      globalProviderContainer
          .read(userLocationsProvider.notifier)
          .updateLocation(myId, position.latitude, position.longitude);
    }

    debugPrint("📍 Location updated ✅");
  }
}
