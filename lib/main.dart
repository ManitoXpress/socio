import 'package:cloud_firestore/cloud_firestore.dart';
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
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  runApp(
    ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MyApp(),
    ),
  );
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

      if (!userDoc.exists) {
        // Si el usuario no existe en Firestore, cerrar sesión
        await FirebaseAuth.instance.signOut();
        currentUser = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, // Habilitar la persistencia local de Firestore
    );

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
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF84090D),
        ),
      ),
      // Mostrar LoadingScreen si está cargando; de lo contrario, HomeScreen o LoginScreen
      home: isLoading
          ? LoadingScreen() // Pantalla de carga
          : (currentUser != null ? HomeScreen() : LoginScreen(deviceId: '')),
    );
  }
}