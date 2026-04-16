import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthUtils {
  static Future<String?> getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String? idToken = await user.getIdToken();
        return idToken;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  static Future<String?> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? deviceId;

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Usa id en lugar de androidId
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor; // Para iOS
      }

      print('Device ID: $deviceId'); // Imprimir el ID del dispositivo
    } catch (e) {
    }

    return deviceId;
  }
}
