import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socio/Utils/remoteNotification.dart';
import 'firebase_options.dart';
import 'menu/Loading.dart';
import 'menu/login.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
// Handler para mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  // Aquí puedes manejar la lógica adicional para mensajes en segundo plano
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

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = true;
  late NotificationService notificationService;

  @override
  void initState() {
    super.initState();
    notificationService = NotificationService(); // Inicializar NotificationService
    notificationService.initNotifications(context); // Inicializar notificaciones con contexto
    _requestTrackingPermission(); // Solicitar permisos de tracking en iOS
    _initializeFirebaseMessaging(); // Inicializar Firebase Messaging
    Future.delayed(const Duration(seconds: 10), () {
      setState(() {
        isLoading = false; // Simulación de carga inicial
      });
    });
  }

  // Solicitar permiso de App Tracking Transparency en iOS
  Future<void> _requestTrackingPermission() async {
    final TrackingStatus status =
        await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 200));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  // Inicializar Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicitar permisos de notificaciones en iOS
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Obtener el token FCM para enviar notificaciones
    String? token = await messaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      sendTokenToServer(token); // Enviar token al servidor
    }

    // Escuchar mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Mensaje recibido en primer plano: ${message.messageId}");
      notificationService.handleNotification(
          message, context); // Mostrar notificación local
    });

    // Manejar cuando la app se abre desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App abierta desde notificación: ${message.messageId}");
      notificationService.handleNotification(
          message, context); // Manejar acción específica
    });
  }

  // Función para enviar el token al servidor
  void sendTokenToServer(String token) {
    // Aquí implementas el envío del token al backend
    print('Enviando token al servidor: $token');
    // Ejemplo de cómo podrías implementarlo:
    FirebaseFirestore.instance
        .collection('tokens')
        .doc(token)
        .set({'token': token, 'timestamp': DateTime.now()});
  }

  @override
  Widget build(BuildContext context) {
    // Configurar Firestore para persistencia
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    return ScreenUtilInit(
      designSize: Size(375, 800), // Tamaño base de diseño
      minTextAdapt: true,
      splitScreenMode: true, // Tamaño base de diseño (ajústalo según tu diseño)
      builder: (context, child) {
        return MaterialApp(
          title: 'ManitoXpress Socio',
          theme: ThemeData(
            primarySwatch: MaterialColor(
              0xFF84090D,
              <int, Color>{
                50: Color(0xFF84090D),
                100: Color(0xFF84090D),
                200: Color(0xFF84090D),
                300: Color(0xFF84090D),
                400: Color(0xFF84090D),
                500: Color(0xFF84090D),
                600: Color(0xFF84090D),
                700: Color(0xFF84090D),
                800: Color(0xFF84090D),
                900: Color(0xFF84090D),
              },
            ),
            colorScheme: ColorScheme.fromSwatch().copyWith(
              secondary: Colors.grey,
              background: Colors.white,
              onBackground: Colors.grey,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF84090D), // Color de fondo del AppBar
            ),
          ),
          home: isLoading ? LoadingScreen() : LoginScreen(deviceId: '',),
        );
      },
    );
  }
}
