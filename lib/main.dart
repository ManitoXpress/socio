import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socio/Screens/Home.dart';
import 'package:socio/Utils/fcmToken.dart';
import 'package:socio/Utils/remoteNotification.dart';
import 'firebase_options.dart';
import 'menu/Loading.dart';
import 'menu/login.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Es importante inicializar Firebase cuando se reciba una notificación en segundo plano.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");

  // Manejar la notificación en segundo plano con NotificationService

}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configurar el handler para mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  // Inicializar el servicio de notificaciones
  await FCMService().init();



  // Obtener y guardar Device ID
  final deviceId = await obtenerDeviceId();
  print("Device ID: $deviceId");




  runApp(
    ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MyApp(),
    ),
  );
}
Future<String> obtenerDeviceId() async {
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final id = androidInfo.id?.toString() ?? 'Unknown Device ID';
      return id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final id = iosInfo.identifierForVendor?.toString() ?? 'Unknown Device ID';
      return id;
    } else {
      return 'Unsupported Platform';
    }
  } catch (e) {
    print('Error obteniendo Device ID: $e');
    return 'Error Device ID';
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? currentUser;
  bool isLoading = true;
  

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  // Inicia el proceso de carga con un retraso mínimo de 5 segundos
  Future<void> _startLoading() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      await Future.wait([
        Future.delayed(const Duration(seconds: 5)), // Retraso mínimo de 5 segundos
        _checkUser(), // Verificar autenticación
      ]);
    } catch (e) {
      print("Error durante la carga: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Verificar si el usuario está autenticado y existe en Firestore
  Future<void> _checkUser() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    currentUser = auth.currentUser;

    if (currentUser != null) {
      // Consultar Firestore para verificar si el usuario existe
      final userDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(currentUser!.uid)
          .get();

    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    return ScreenUtilInit(
      designSize: Size(375, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Manitos Xpress',
        theme: ThemeData(
          primarySwatch: MaterialColor(
            0xFF84090D,
            <int, Color> {
              50: Color(0xFF84090D),
              100: Color(0xFF84090D),
              200: Color(0xFF84090D),
              300: Color(0xFF84090D),
              400: Color(0xFF84090D),
              500: Color(0xFF84090D),
              600: Color(0xFF84090D),
              700: Color(0xFF84090D),
              800: Color(0xFF84090D),
              900: Color.fromRGBO(26, 129, 154, 1),
            },
          ),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Colors.grey,
            background: Colors.white,
            onBackground: Colors.grey,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF84090D),
          ),
        ),
        home: isLoading ? LoadingScreen() : LoginScreen(deviceId: ''),
      ),
    );
  }
}