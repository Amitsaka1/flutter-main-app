import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────
// Sabhi users ki locations store karta hai
// { "userId123": {"latitude": 28.6, "longitude": 77.2} }
// ─────────────────────────────────────────────

final userLocationsProvider =
    StateNotifierProvider<UserLocationsNotifier, Map<String, Map<String, double>>>(
  (ref) => UserLocationsNotifier(),
);

class UserLocationsNotifier
    extends StateNotifier<Map<String, Map<String, double>>> {

  UserLocationsNotifier() : super({});

  // ── Ek user ki location update karo ──────────
  void updateLocation(String userId, double latitude, double longitude) {
    state = {
      ...state,
      userId: {
        "latitude":  latitude,
        "longitude": longitude,
      },
    };
  }

  // ── Saari locations ek saath set karo (login pe) ──
  void setAllLocations(List<dynamic> locations) {
    final Map<String, Map<String, double>> newMap = { ...state };

    for (final loc in locations) {
      final userId = loc["userId"]?.toString();
      final lat    = (loc["latitude"]  as num?)?.toDouble();
      final lng    = (loc["longitude"] as num?)?.toDouble();

      if (userId != null && lat != null && lng != null) {
        newMap[userId] = {
          "latitude":  lat,
          "longitude": lng,
        };
      }
    }

    state = newMap;
  }

  // ── Logout pe clear karo ─────────────────────
  void clear() => state = {};
}
