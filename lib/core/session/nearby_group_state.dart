import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// "Official Group" tile Home screen pe **permanently** rehta hai (jaisa
/// design kiya tha) -- ye us tile ka state hai: kaunsa radius last select
/// kiya tha, kab update hua. flutter_secure_storage already ek dependency
/// hai (ApiClient use karta hai token ke liye), isliye koi naya package
/// nahi chahiye.
class NearbyGroupState {
  static const _storage = FlutterSecureStorage();
  static const _key = 'nearby_official_group';

  final double radiusKm;
  final double latitude;
  final double longitude;
  final List<String> channels;
  final DateTime lastUpdated;

  NearbyGroupState({
    required this.radiusKm,
    required this.latitude,
    required this.longitude,
    required this.channels,
    required this.lastUpdated,
  });

  static Future<NearbyGroupState?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return NearbyGroupState(
        radiusKm: (map['radiusKm'] as num).toDouble(),
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        channels: List<String>.from(map['channels'] ?? []),
        lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save({
    required double radiusKm,
    required double latitude,
    required double longitude,
    required List<String> channels,
  }) async {
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'radiusKm': radiusKm,
        'latitude': latitude,
        'longitude': longitude,
        'channels': channels,
        'lastUpdated': DateTime.now().toIso8601String(),
      }),
    );
  }
}
