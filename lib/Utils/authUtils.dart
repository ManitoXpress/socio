import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthUtils {
  static Future<String?> getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    print('[AuthUtils.getToken] Usuario actual: ' + (user?.uid ?? 'null'));
    if (user != null) {
      try {
        String? idToken = await user.getIdToken();
        print('[AuthUtils.getToken] Token obtenido: ' + (idToken ?? 'null'));
        return idToken;
      } catch (e) {
        print('[AuthUtils.getToken] Error al obtener el token: $e');
        return null;
      }
    }
    print('[AuthUtils.getToken] Usuario es null, no autenticado');
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
      print('Error al obtener el ID del dispositivo: $e');
    }

    return deviceId;
  }
}
