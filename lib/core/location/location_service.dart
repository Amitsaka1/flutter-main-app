import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_project/core/network/api_client.dart';

class LocationService {

  // ─────────────────────────────────────────────
  // Login ke baad ye call karo
  // Permission allow → location send
  // Permission deny  → silently skip, koi error nahi
  // ─────────────────────────────────────────────
  static Future<void> updateLocationOnLogin() async {
    try {

      // Step 1: GPS service on hai?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("📍 GPS service disabled — skip");
        return;
      }

      // Step 2: Permission check
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Pehli baar — system dialog dikhao
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("📍 Permission denied — skip");
          return; // ✅ Silently skip — app normal chalta rahe
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("📍 Permission permanently denied — skip");
        return; // ✅ Silently skip
      }

      // Step 3: GPS location lo
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // Battery save
          timeLimit: Duration(seconds: 10),  // Max 10 sec wait
        ),
      );

      debugPrint("📍 Location: ${position.latitude}, ${position.longitude}");

      // Step 4: Backend ko bhejo
      await ApiClient.patch("/profile/location", {
        "latitude":  position.latitude,
        "longitude": position.longitude,
      });

      debugPrint("📍 Location updated ✅");

    } catch (e) {
      // ✅ Silent fail — location ke liye app crash nahi hogi
      debugPrint("📍 Location update failed (silent): $e");
    }
  }
}
