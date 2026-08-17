class UserSession {
  static String? userId;
  static String? name;
  static String? avatarUrl;
  static bool    locationEnabled = false;

  static void setUserId(String id) {
    userId = id;
  }

  static void setProfile({
    required String name,
    String?         avatarUrl,
  }) {
    UserSession.name      = name;
    UserSession.avatarUrl = avatarUrl;
  }

  static String? getUserId() => userId;

  static void clear() {
    userId          = null;
    name            = null;
    avatarUrl       = null;
    locationEnabled = false;
  }
}
