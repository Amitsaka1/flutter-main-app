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

    throw Exception(response["message"] ?? "Failed to load rooms");
  }

  /// 🔹 Create Room
  static Future<void> createRoom({
    required String userId,
    required String name,
    String? description,
  }) async {

    final response = await ApiClient.post(
      "/room/create",
      {
        "userId": userId,
        "name": name,
        "description": description ?? "",
      },
    );

    if (response["success"] != true) {
      throw Exception(response["message"] ?? "Room creation failed");
    }
  }

  /// 🔹 Join Room
  static Future<void> joinRoom({
    required String userId,
    required String roomId,
  }) async {

    final response = await ApiClient.post(
      "/room/join",
      {
        "userId": userId,
        "roomId": roomId,
      },
    );

    if (response["success"] != true) {
      throw Exception(response["message"] ?? "Join failed");
    }
  }

  /// 🔹 Leave Room
  static Future<void> leaveRoom({
    required String userId,
    required String roomId,
  }) async {

    final response = await ApiClient.post(
      "/room/leave",
      {
        "userId": userId,
        "roomId": roomId,
      },
    );

    if (response["success"] != true) {
      throw Exception(response["message"] ?? "Leave failed");
    }
  }
}
