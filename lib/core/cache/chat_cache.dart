class ChatCache {
  static List<dynamic>? _cachedChats;
  static DateTime? _lastFetch;

  // 🔥 Return copy to prevent external mutation
  static List<dynamic>? get chats =>
      _cachedChats != null ? List.from(_cachedChats!) : null;

  static bool get hasCache => _cachedChats != null;

  static void save(List<dynamic> data) {
    _cachedChats = List.from(data); // 🔥 store copy
    _lastFetch = DateTime.now();
  }

  static bool get isFresh {
    if (_lastFetch == null) return false;
    return DateTime.now()
            .difference(_lastFetch!)
            .inSeconds <
        20;
  }

  static void clear() {
    _cachedChats = null;
    _lastFetch = null;
  }
}
