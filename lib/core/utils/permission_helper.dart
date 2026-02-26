import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestCallPermissions() async {
    final mic = await Permission.microphone.request();
    final camera = await Permission.camera.request();

    return mic.isGranted && camera.isGranted;
  }
}
