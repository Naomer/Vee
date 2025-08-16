import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestMicrophonePermission() async {
    try {
      // Check if we already have permission
      var status = await Permission.microphone.status;
      if (status.isGranted) {
        return true;
      }

      // Request permission
      status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting microphone permission: $e');
      return false;
    }
  }
}
