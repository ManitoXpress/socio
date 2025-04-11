import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socio/Screens/Home.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/fcmToken.dart';

import 'firebase_options.dart';
import 'menu/Loading.dart';
import 'menu/login.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Es importante inicializar Firebase cuando se reciba una notificación en segundo plano.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");

  // Manejar la notificación en segundo plano con NotificationService
  // Aquí puedes agregar la lógica para mostrar la notificación
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
  if (Platform.isIOS) {
    await requestTrackingPermission(); // Solo en iOS
  }

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
      builder: (context, child) => MyApp(deviceId: deviceId),
    ),
  );
}
Future<void> requestTrackingPermission() async {
  if (Platform.isIOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      final result = await AppTrackingTransparency.requestTrackingAuthorization();
      print("Estado de ATT: \$result");
    }
  }
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
  final String deviceId;

  const MyApp({required this.deviceId});

  @override
  _MyAppState createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isLoading = true;
  bool isLoggedIn = false;
  UserData? userData;
  RegistrationData? registrationData;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    isLoading = true;
    _checkLoginStatus(); // Llama directamente a la función
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (loggedIn) {
      // Obtén el usuario actual
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Obtén los datos del usuario y de registro
        userData = await fetchUserData(user.uid);
        registrationData = userData?.registrationData;
      }
    }

    // Simular tiempo de carga si es necesario
    await Future.delayed(const Duration(seconds: 5));

    setState(() {
      isLoggedIn = loggedIn;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('App is in foreground');
    } else if (state == AppLifecycleState.paused) {
      print('App is in background');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Manitos Xpress Socio',
        theme: ThemeData(
          primarySwatch: MaterialColor(
            0xFF1A819A,
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
            backgroundColor: Color(0xFF84090D),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => isLoading ? LoadingScreen() : (isLoggedIn ? HomeScreen(userData: userData!, registrationData: registrationData!) : LoginScreen(deviceId: widget.deviceId)),
          '/home': (context) => HomeScreen(userData: userData!, registrationData: registrationData!),  // Ruta definida para 'HomeScreen'
        },
        );
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