import '../../../core/network/api_client.dart';

class RoomApi {

  /// 🔹 Get Room List
  static Future<List<dynamic>> getRooms() async {
    final response = await ApiClient.get(
      "/room/list",
      queryParams: {
        "type": "ALL",
      },
    );

    if (response["success"] == true) {
      return response["rooms"] ?? [];
    }

    return [];
  }

  /// 🔹 Join Room
  static Future<void> joinRoom(
    String userId,
    String roomId,
  ) async {
    await ApiClient.post(
      "/room/join",
      {
        "userId": userId,
        "roomId": roomId,
      },
    );
  }

  /// 🔹 Leave Room
  static Future<void> leaveRoom(
    String userId,
    String roomId,
  ) async {
    await ApiClient.post(
      "/room/leave",
      {
        "userId": userId,
        "roomId": roomId,
      },
    );
  }
}
