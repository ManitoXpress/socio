
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:socio/Controller/RegisController.dart';
import 'package:socio/Screens/Home.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
class NotificationService {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationService() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  Future<void> initNotifications(BuildContext context) async {
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
        print('Notificación seleccionada: ${response.payload}');
        // Navegar a la pantalla de inicio cuando la notificación es seleccionada
        if (response.payload != null) {
          _navigateToHomeScreen(context, response.payload!);
        }
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleNotification(message, context); // Pasar el contexto aquí
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotification(message, context); // Pasar el contexto aquí
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  void handleNotification(RemoteMessage message, BuildContext context) {
    if (message.data['status'] == 'offer') {
      showNotificationWithAction(
        message.notification?.title ?? 'Nuevo servicio ofertado',
        message.notification?.body ?? 'Tienes una nueva oferta para tu servicio.',
        message.data['serviceId'] ?? '',
      );
    }
  }

  Future<void> showNotificationWithAction(
      String title, String body, String serviceId) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'service_offers_channel',
      'Service Offers',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('accept', 'Aceptar'),
        AndroidNotificationAction('reject', 'Rechazar'),
      ],
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: serviceId,
    );
  }

  void _navigateToHomeScreen(BuildContext context, String serviceId) async {
    try {
      // Obtén el usuario actual
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Obtén los datos del usuario y de registro
        UserData userData = await fetchUserData(user.uid);
        RegistrationData registrationData = userData.registrationData;

        // Navega a HomeScreen con los datos obtenidos
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userData: userData,
              registrationData: registrationData,
            ),
          ),
        );
      } else {
        print('Advertencia: usuario es nulo. Asegúrate de que el usuario esté autenticado correctamente.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error de autenticación. Intente nuevamente.')));
      }
    } catch (error) {
      print('Error al navegar a HomeScreen: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar la pantalla principal. Intente nuevamente.')));
    }
  }

// Ejemplo de función para obtener los datos del usuario
  Future<UserData> fetchUserData(String userId) async {
    // Aquí debes implementar la lógica para obtener los datos del usuario
    // Por ejemplo, desde una base de datos o un servicio web
    // Este es solo un ejemplo de retorno
    return UserData(
      userId: userId,
      displayName: '',
      idCardNumber: '',
      phoneNumber: '',
      getToken: null,
      imagePath: '',
      pdfPathController: '',
      criminalRecordImagePath: '',
      idDocumentImagePath: '',
      idDocumentImagePath2: '',
      selectedCountryCode: '',
      expertises: [],
      expLevel: [],
      certificateImagePaths: '',
      location: null,
      paymentType: '',
      email: '',
      registrationData: RegistrationData(
        userId: userId,
        devicesId: '',
        fcmToken: '',
        displayName: '',
        idCardNumber: '',
        phoneNumber: '',
        paymentType: '',
        expertises: [],
        expLevel: [],
        selectedCountryCode: '',
        imagePath: '',
        location: null,
        idDocumentImagePath: '',
        idDocumentImagePath2: '',
        email: '',
        imagePathList: [],
        criminalRecordImagePath: '',
        certificateImagePaths: '',
        referralCode: '',
        points: 0,
        codeReferral: '', verificationStatus: '',
      ),
      referrerWorkerId: '',
      referralCode: '',
      points: 0, verificationStatus: '',
    );
  }


  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // Maneja los mensajes en segundo plano aquí si es necesario
  }

  Future<void> requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
  }

  // Método para registrar el FCM Token y el deviceId en Firestore
  Future<void> registerFCMToken() async {
    try {
      // Obtener el FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Obtener el deviceId usando "device_info_plus"
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String? deviceId;

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Para Android, usa 'id'
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor; // Para iOS
      }

      // Verifica si ambos valores no son nulos
      if (fcmToken != null && deviceId != null) {
        // Verificar si ya existe un documento con este deviceId
        DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
            .collection('services')
            .doc(deviceId)
            .get();

        if (documentSnapshot.exists) {
          // Si ya existe el documento, solo actualizamos el FCM token
          await FirebaseFirestore.instance
              .collection('services')
              .doc(deviceId)
              .update({
            'fcmToken': fcmToken,
          });
          print("FCM Token actualizado en Firestore.");
        } else {
          // Si no existe el documento, lo creamos
          await FirebaseFirestore.instance
              .collection('services')
              .doc(deviceId)
              .set({
            'deviceId': deviceId,
            'fcmToken': fcmToken,
          });
          print("FCM Token y Device ID guardados en Firestore con éxito.");
        }
      } else {
        print("Error: No se pudo obtener el deviceId o el fcmToken.");
      }
    } catch (e) {
      print("Error al registrar el FCM Token: $e");
    }
  }
}