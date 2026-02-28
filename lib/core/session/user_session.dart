class UserSession {
  static String? userId;

  static void setUserId(String id) {
    userId = id;
  }

  static String? getUserId() {
    return userId;
  }

  static void clear() {
    userId = null;
  }
}
