import 'dart:io';
import 'package:rive/rive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socio/Utils/fcmToken.dart';
import 'package:socio/provider/providerRegistration.dart';
import 'package:socio/provider/providerService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Screens/Home.dart';
import 'ServiceResponse/get.dart';
import 'ServiceResponse/post.dart';
import 'ServiceResponse/requestUserData.dart';
import 'controllers/RegisController.dart';
import 'provider/providerImage.dart';
import 'firebase_options.dart';
import 'menu/Loading.dart';
import 'menu/login.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'Utils/debt_blocker_wrapper.dart';

import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Es importante inicializar Firebase cuando se reciba una notificación en segundo plano.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveFile.initialize();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (e is FirebaseException && e.code == 'duplicate-app') {
    } else {
    }
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
    );
  } catch (e) {
  }

  // El permiso de notificaciones es llamado en initState de MyApp.
  // Quitarlo del main() evita que congele el renderizado inicial (Pantalla negra)
  // await requestNotificationPermissions();
  final deviceId = await obtenerDeviceId();
  // ApiService y RegistrationController
  final apiService = ApiService();
  final regController = RegistrationController();
  final regCallback = () => print("Registro completado");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageStateProvider()),
        ChangeNotifierProvider(create: (_) => HistorialProvider()),
        ChangeNotifierProvider(
          create: (_) => RegistrationProvider(
            registrationController: regController,
            completeRegistrationCallback: regCallback,
            apiService: apiService,
          ),
        ),
      ],
      child: ScreenUtilInit(
        designSize: Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MyApp(deviceId: deviceId),
      ),
    ),
  );
}

Future<void> requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
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

    // Espera al primer render para no bloquear la UI:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestLocationPermissions();
      requestNotificationPermissions(); // 🔔 Solicita permiso de notificaciones
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (loggedIn) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userData = await fetchUserData(user.uid);
        registrationData = userData?.registrationData;
        
        // Safety check: if user data failed to load, revert login state
        if (userData == null || registrationData == null) {
          loggedIn = false;
          await prefs.setBool('isLoggedIn', false);
        }
      } else {
        // user is null but prefs say true, fix it
        loggedIn = false;
        await prefs.setBool('isLoggedIn', false);
      }
    }

    // Simula tiempo de carga si es necesario
    await Future.delayed(const Duration(seconds: 5));

    setState(() {
      isLoggedIn = loggedIn;
      isLoading = false;
    });
  }

  Future<void> requestLocationPermissions() async {
    // Pido permiso sólo mientras la app está en uso
    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      // Si necesito ubicación en background:
      if (await Permission.locationAlways.isDenied) {
        await Permission.locationAlways.request();
      }
    }
    // Removido else if (status.isPermanentlyDenied) para que NO vaya a configuraciones directamente
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
    } else if (state == AppLifecycleState.paused) {
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
      home: isLoading
          ? LoadingScreen()
          : isLoggedIn
              ? DebtBlockerWrapper(
                  child: HomeScreen(
                      userData: userData!, registrationData: registrationData!),
                )
              : LoginScreen(deviceId: widget.deviceId),
    );
  }
}

/// Lee los datos del worker desde Firestore
Future<UserData> fetchUserData(String userId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('workers')
        .doc(userId)
        .get();
    final data = doc.data();
    if (data != null) {
      data['id'] = userId;
      return UserData.fromJson(data);
    }
  } catch (e) {
    debugPrint('fetchUserData error: $e');
  }
  // Fallback mínimo si Firestore falla
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
    medicalLicenseImagePath: '',
    professionalTitleImagePath: '',
    selectedCountryCode: '',
    expertises: [],
    expLevel: [],
    certificateImagePaths: [],
    location: null,
    paymentType: '',
    email: '',
    referrerWorkerId: '',
    referralCode: '',
    verificationStatus: '',
    points: 0,
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
      certificateImagePaths: [],
      referralCode: '',
      points: 0,
      codeReferral: '',
      verificationStatus: '',
    ),
  );
}
