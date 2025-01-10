import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socio/Screens/Home.dart';
import 'package:socio/Utils/remoteNotification.dart';
import 'firebase_options.dart';
import 'menu/Loading.dart';
import 'menu/login.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  final deviceId = await obtenerDeviceId();
  print("Device ID: $deviceId");

  runApp(MyApp(deviceId: deviceId));
}

Future<String> obtenerDeviceId() async {
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id?.toString() ?? 'Unknown Device ID';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor?.toString() ?? 'Unknown Device ID';
    } else {
      return 'Unsupported Platform';
    }
  } catch (e, stackTrace) {
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

class _MyAppState extends State<MyApp> {
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      setState(() {
        isLoading = false;
      });
    });
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
        home: isLoading ? LoadingScreen() : LoginScreen(deviceId: widget.deviceId),
      ),
    );
  }
}