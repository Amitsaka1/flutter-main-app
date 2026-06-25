// Web ke liye — empty implementation
// sqflite web pe kaam nahi karta
// Mobile pe cache_service_impl.dart use hoga

class CacheService {
  CacheService._internal();
  static final CacheService instance = CacheService._internal();

  Future<void> saveProfiles(List<dynamic> p)  async {}
  Future<List<dynamic>> getProfiles()          async => [];

  Future<void> saveChats(List<dynamic> c)     async {}
  Future<List<dynamic>> getChats()             async => [];

  Future<void> saveMessages(
      String conversationId, List<dynamic> m) async {}
  Future<List<dynamic>> getMessages(
      String conversationId)                   async => [];

  Future<void> saveRooms(List<dynamic> r)     async {}
  Future<List<dynamic>> getRooms()             async => [];

  Future<void> saveMyProfile(
      Map<String, dynamic> p)                  async {}
  Future<Map<String, dynamic>?> getMyProfile() async => null;

  Future<void> addToQueue(
      String tempId,
      String conversationId,
      Map<String, dynamic> data)               async {}
  Future<List<Map<String, dynamic>>> getQueue() async => [];
  Future<void> removeFromQueue(String id)      async {}

  Future<void> clearAll()                      async {}
}
