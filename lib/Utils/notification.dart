
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class NotificationService {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationService() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _createNotificationChannel(); // Crear el canal de notificación
    initNotifications(); // Inicializa las notificaciones
  }

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        handleNotificationResponse(response);
      },
    );
  }

  // Crear el canal de notificación en el sistema
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // ID único del canal
      'High Importance Notifications', // Nombre del canal visible para el usuario
      description: 'This channel is used for important notifications.', // Descripción del canal
      importance: Importance.high, // Importancia del canal
    );

    // Crear el canal de notificación en Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Manejar la respuesta a la notificación (Aceptar o Rechazar)
  void handleNotificationResponse(NotificationResponse response) {
    // Aquí puedes manejar la acción según la respuesta de la notificación
  }

  // Mostrar una notificación local
  Future<void> showLocalNotification(String title, String body, String payload) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel', // Debe coincidir con el ID del canal creado
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
    );

    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0, // ID de la notificación
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Método de ejemplo para mostrar una notificación de prueba
  Future<void> showTestNotification() async {
    await showLocalNotification('Nueva Oferta', 'Tienes una nueva oferta para tu servicio.', 'test_payload');
  }

  Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (kIsWeb) {
      deviceId = 'Web';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }

    return deviceId;
  }
}
