import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rive/rive.dart' as rive; // Alias para Rive
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/Metods/loginController.dart';
import 'package:socio/Screens/Home.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/menu/register.dart';
import 'package:socio/menu/welcome.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key, required String deviceId}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginScreen> {
  late String animationURL;
  rive.Artboard? _teddyArtboard;
  rive.SMITrigger? successTrigger, failTrigger;
  rive.SMIBool? isHandsUp, isChecking;
  rive.SMINumber? numLook;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  List<ServiceRequest> serviceRequests = [];
  bool isPasswordVisible = false;
  bool isLoadingGoogle = false;  // Indicador de carga para Google
  bool isLoadingApple = false;  // Indicador de carga para Apple

  rive.StateMachineController? stateMachineController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final loginController = LoginScreenController();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  @override
  void initState() {
    super.initState();
    animationURL = defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS
        ? 'assets/animations/login.riv'
        : 'animations/login.riv';
    rootBundle.load(animationURL).then(
      (data) {
        final file = rive.RiveFile.import(data);
        final artboard = file.mainArtboard;
        stateMachineController =
            rive.StateMachineController.fromArtboard(artboard, "State Machine 1");
        if (stateMachineController != null) {
          artboard.addController(stateMachineController!);

          stateMachineController!.inputs.forEach((element) {
            switch (element.name) {
              case "success":
                successTrigger = element as rive.SMITrigger;
                break;
              case "fail":
                failTrigger = element as rive.SMITrigger;
                break;
              case "hands_up":
                isHandsUp = element as rive.SMIBool;
                break;
              case "idle":
                isChecking = element as rive.SMIBool;
                break;
              case "Look_down_left":
                numLook = element as rive.SMINumber;
                break;
              default:
                break;
            }
          });
        }

        setState(() => _teddyArtboard = artboard);
      },
    );
   // Mostrar el AlertDialog después de cargar la pantalla de inicio de sesión
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Términos y Condiciones"),
            content: TextButton(
              onPressed: () {
                launch('https://manitoxpress-cf855.web.app/#/PrivacyPage');
              },
              child: Text(
                'Al iniciar sesión, aceptas nuestros Términos y Condiciones.',
                style: TextStyle(
                  color: Color.fromARGB(255, 2, 8, 168),
                  fontSize: 16, // Cambia el tamaño según tu preferencia
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text("Aceptar"),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFFB00020), // Color del texto, el mismo que el borde
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(
                      color: Color(0xFFB00020), // Color del borde
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),

            ],
          );
        },
      );
    });
  }
  
  

  Future<void> login() async {
    isChecking?.change(false);
    isHandsUp?.change(false);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final userDoc = await _firestore.collection('workers').doc(userCredential.user?.uid).get();

      if (userDoc.exists) {
        successTrigger?.fire();
        LoginScreenController.signInWithGoogle(context);
      } else {
        failTrigger?.fire();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Usuario no encontrado"),
              content: Text("El usuario no existe en la colección de workers."),
              actions: [
                TextButton(
                  child: Text("Aceptar"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      failTrigger?.fire();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Inicio de sesión fallido"),
            content: Text("Email o contraseña incorrectos. Inténtalo de nuevo."),
            actions: [
              TextButton(
                child: Text("Aceptar"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
  

  Future<void> signInWithGoogle() async {
    setState(() => isLoadingGoogle = true);
    try {
      await LoginScreenController.signInWithGoogle(context);
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
    } finally {
      setState(() => isLoadingGoogle = false);
    }
  }

  Future<void> signInWithApple() async {
    setState(() {
      isLoadingApple = true;
    });

    try {
      await LoginScreenController.signInWithApple(context);
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
    } finally {
      setState(() => isLoadingGoogle = false);
    }
  }

  void _showTermsAndConditionsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar el diálogo al tocar fuera de él
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Términos y Condiciones'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Al iniciar sesión, aceptas nuestros Términos y Condiciones.',
                style: TextStyle(
                  color: Color.fromARGB(255, 168, 2, 2),
                  fontSize: 16.sp,
                  decoration: TextDecoration.underline, // Subrayado
                ),
              ),
              SizedBox(height: 10.h),
              TextButton(
                onPressed: () {
                  // Acciones para abrir el link de términos y condiciones
                  // Por ejemplo, puedes usar url_launcher
                  _launchTermsAndConditionsUrl();
                },
                child: Text(
                  'Ver Términos y Condiciones',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.blue,
                    decoration: TextDecoration.underline, // Subrayado
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text(
                'Aceptar',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Color(0xFF84090D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _launchTermsAndConditionsUrl() async {
    const url = 'https://manitoxpress-cf855.web.app/#/PrivacyPage'; // URL de tus términos y condiciones
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se pudo abrir el enlace: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd6e2ea),
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w),
                constraints: BoxConstraints(maxWidth: 0.2.sw),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  width: 0.2.sw,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'ManitoXpress',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Xpress Heavy',
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
                fontSize: 20.sp,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 1.sw,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_teddyArtboard != null)
                  SizedBox(
                    width: 0.8.sw,
                    height: 0.38.sh,
                    child: rive.Rive(
                      artboard: _teddyArtboard!,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                SizedBox(height: 10.h),
                Text(
                  'Bienvenidos a Manitos Xpress',
                  style: MyTextStyles.buttonTextStyle3,
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón de Google
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF84090D),
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(3.w),
                      ),
                      onPressed: isLoadingGoogle ? null : signInWithGoogle,
                      child: isLoadingGoogle
                          ? CircularProgressIndicator() // Indicador de carga
                          : CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 40.r,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 37.r,
                                child: CircleAvatar(
                                  radius: 35.r,
                                  backgroundColor: Colors.white,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.google,
                                        color: Color(0xFF84090D),
                                      ),
                                      Text(
                                        'Inicio',
                                        style: GoogleFonts.lato(
                                          color: Color(0xFF84090D),
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    SizedBox(width: 10.w), // Espacio entre los botones
                    // Botón de Apple
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF84090D),
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(3.w),
                      ),
                      onPressed: isLoadingApple ? null : signInWithApple,
                      child: isLoadingApple
                          ? CircularProgressIndicator() // Indicador de carga
                          : CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 40.r,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 37.r,
                                child: CircleAvatar(
                                  radius: 35.r,
                                  backgroundColor: Colors.white,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.apple,
                                        color: Color(0xFF84090D),
                                      ),
                                      Text(
                                        'Apple',
                                        style: GoogleFonts.lato(
                                          color: Color(0xFF84090D),
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                SizedBox(height: 70.h),
                ElevatedButton.icon(
                  onPressed: () {
                    // Acción de borrar cuenta
                  },
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text(
                    "Eliminar cuenta",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Color(0xFF84090D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                        color: Color(0xFF84090D),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
