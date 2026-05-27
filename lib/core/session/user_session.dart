class UserSession {
  static String? userId;
  static String? name;
  static String? avatarUrl;
  static int     level = 1;

  static void setUserId(String id) {
    userId = id;
  }

  static void setProfile({
    required String name,
    String?         avatarUrl,
    int             level = 1,
  }) {
    UserSession.name      = name;
    UserSession.avatarUrl = avatarUrl;
    UserSession.level     = level;
  }

  static String? getUserId() => userId;

  static void clear() {
    userId    = null;
    name      = null;
    avatarUrl = null;
    level     = 1;
  }
}
