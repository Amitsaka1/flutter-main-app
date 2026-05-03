import 'dart:async';

class GlobalDataManager {
  GlobalDataManager._internal();
  static final GlobalDataManager instance =
      GlobalDataManager._internal();

  // =========================
  // 🔥 DATA STORAGE
  // =========================

  List<dynamic>? profiles;
  List<dynamic>? chats;
  List<dynamic>? rooms;

  int unreadCount = 0;

  // =========================
  // 🔥 STREAM (UI update)
  // =========================

  final StreamController<void> _controller =
      StreamController.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    _controller.add(null);
  }

  // =========================
  // 🔥 SET DATA
  // =========================

  void setProfiles(List<dynamic> data) {
    profiles = data;
    notify();
  }

  void setChats(List<dynamic> data) {
    chats = data;
    notify();
  }

  void setRooms(List<dynamic> data) {
    rooms = data;
    notify();
  }

  void setUnread(int count) {
    unreadCount = count;
    notify();
  }

  // =========================
  // 🔥 CLEAR (logout)
  // =========================

  void clear() {
    profiles = null;
    chats = null;
    rooms = null;
    unreadCount = 0;
    notify();
  }
}
