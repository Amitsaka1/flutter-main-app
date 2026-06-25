import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/cache_service.dart';
import 'api_client.dart';

// ─────────────────────────────────────────────
// Internet aane pe queued messages auto-send
// ─────────────────────────────────────────────

class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;

  // ─────────────────────────────────────────────
  // main.dart mein ek baar start karo
  // ─────────────────────────────────────────────
  void start() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((result) {
      final isOnline = result != ConnectivityResult.none;
      if (isOnline) {
        debugPrint("🌐 Internet aaya — queue sync start");
        _syncQueue();
      }
    });

    // App open pe bhi ek baar check karo
    _syncQueue();
  }

  void stop() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  // ─────────────────────────────────────────────
  // Queue mein pade messages bhejo
  // ─────────────────────────────────────────────
  Future<void> _syncQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // Internet hai?
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        debugPrint("🌐 Offline — sync skip");
        return;
      }

      // Queue se sab pending messages lo
      final queue = await CacheService.instance.getQueue();

      if (queue.isEmpty) {
        debugPrint("✅ Queue empty — kuch nahi bhejna");
        return;
      }

      debugPrint("📤 Queue mein ${queue.length} messages hain — bhej raha hoon");

      for (final item in queue) {
        try {
          final conversationId = item["conversation_id"] as String;
          final data           = item["data"] as Map<String, dynamic>;
          final tempId         = item["id"] as String;
          final content        = data["content"]?.toString() ?? "";

          if (content.isEmpty) {
            // Invalid message — queue se hata do
            await CacheService.instance.removeFromQueue(tempId);
            continue;
          }

          // Backend ko bhejo
          final response = await ApiClient.post("/chat/send", {
            "receiverId": conversationId,
            "content":    content,
          });

          if (response["success"] == true) {
            // ✅ Sent — queue se hata do
            await CacheService.instance.removeFromQueue(tempId);
            debugPrint("✅ Queued message sent: $tempId");
          } else {
            debugPrint("⚠️ Send failed: $tempId — queue mein rakhenge");
          }

        } catch (e) {
          debugPrint("⚠️ Queue item error: $e — next try karenge");
          // Error pe skip karo — agli baar try hoga
        }
      }

    } catch (e) {
      debugPrint("⚠️ Sync failed: $e");
    } finally {
      _isSyncing = false;
    }
  }
}
