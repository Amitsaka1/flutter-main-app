import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_project/core/network/api_client.dart';
import 'package:app_project/core/session/user_session.dart';
import 'package:app_project/providers/user_locations_provider.dart';
import 'package:app_project/core/riverpod/app_container.dart';

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
      // ✅ FIX: deniedForever pehle check karo
      // Kuch Android devices pe pehle se permanently denied hoti hai
      // Aur requestPermission() silently fail karta tha bina dialog ke
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        debugPrint("📍 Permission permanently denied — skip");
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          debugPrint("📍 Permission denied — skip");
          return;
        }
      }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("📍 Permission permanently denied — skip");
        return; // ✅ Silently skip
      }

      // Step 3: GPS location lo
      Position? position;

      try {
        // Fresh GPS try karo — 10s mein nahi mila toh fallback
        position = await Geolocator.getCurrentPosition()
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Fallback: last known location — sirf mobile pe
        if (!kIsWeb) {
          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (position == null) {
        debugPrint("📍 Location unavailable — skip");
        return;
      }
      
      debugPrint("📍 Location: ${position.latitude}, ${position.longitude}");

      // Step 4: Backend ko bhejo
      await ApiClient.patch("/profile/location", {
        "latitude":  position.latitude,
        "longitude": position.longitude,
      });

      // ✅ FIX: Apni location Riverpod mein bhi save karo
      // profile_card pe distance badge ke liye myLoc chahiye
      // fetchAllLocations mein apni location nahi hoti (race condition)
      // Isliye yahan directly Riverpod update karo
      final myId = UserSession.getUserId();
      if (myId != null) {
        globalProviderContainer
            .read(userLocationsProvider.notifier)
            .updateLocation(myId, position.latitude, position.longitude);
      }

      debugPrint("📍 Location updated ✅");

    } catch (e) {
      // ✅ Silent fail — location ke liye app crash nahi hogi
      debugPrint("📍 Location update failed (silent): $e");
    }
  }
}
