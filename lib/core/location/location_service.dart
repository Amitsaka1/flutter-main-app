import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_project/core/network/api_client.dart';
import 'package:app_project/core/session/user_session.dart';
import 'package:app_project/providers/user_locations_provider.dart';
import 'package:app_project/core/riverpod/app_container.dart';

class LocationService {

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
      // ✅ Extra } hata diya, aur duplicate deniedForever check bhi hata diya

      // Step 3: GPS location lo
      Position? position;

      try {
        position = await Geolocator.getCurrentPosition()
            .timeout(const Duration(seconds: 10));
      } catch (_) {
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

      // Step 5: Riverpod update
      final myId = UserSession.getUserId();
      if (myId != null) {
        globalProviderContainer
            .read(userLocationsProvider.notifier)
            .updateLocation(myId, position.latitude, position.longitude);
      }

      debugPrint("📍 Location updated ✅");

    } catch (e) {
      debugPrint("📍 Location update failed (silent): $e");
    }
  }
}
