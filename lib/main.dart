import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Importa flutter_screenutil

import 'firebase_options.dart';
import 'menu/Loading.dart';
import 'menu/login.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Tamaño base de diseño (ajústalo según tu diseño)
      builder: (context, child) => MaterialApp(
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
        home: isLoading ? LoadingScreen() : LoginScreen(),
      ),
    );
  }
}
