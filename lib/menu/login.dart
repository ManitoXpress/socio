import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:socio/controllers/loginController.dart';
import 'package:socio/Screens/Home.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';
import 'package:rive/rive.dart' as rive;
import 'package:google_fonts/google_fonts.dart';

import 'package:socio/Screens/Home.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';

import 'package:socio/Utils/styles.dart';
import 'package:rive/rive.dart' as rive;
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/loginController.dart';

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
  bool isLoadingGoogle = false; // Indicador de carga para Google
  bool isLoadingApple = false; // Indicador de carga para Apple
  bool isLoadingAnonymous = false; // Indicador de carga para Apple

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
        : 'assets/animations/login.riv';
    rootBundle.load(animationURL).then(
      (data) {
        final file = rive.RiveFile.import(data);
        final artboard = file.mainArtboard;
        stateMachineController = rive.StateMachineController.fromArtboard(
            artboard, "State Machine 1");
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
            title: Text(
              "Términos y Condiciones",
              style: MyTextStyles.inputTextStyle4,
            ),
            content: TextButton(
              onPressed: () {
                launch('https://manitoxpress-cf855.web.app/#/PrivacyPage');
              },
              child: Text(
                'Al iniciar sesión, aceptas nuestros Términos y Condiciones.',
                style: MyTextStyles.drawerButtonTextStyle6,
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  "Aceptar",
                  style: MyTextStyles.linkTextStyle,
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.white,
                  foregroundColor: Color(
                      0xFF841813), // Color del texto, el mismo que el borde
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(
                      color: Color(0xFF841813), // Color del borde
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
  Future<void> _signInAsGuest() async {
  setState(() => isLoadingAnonymous = true);
  try {
    // Llamas a tu controlador para manejo uniforme
    await LoginScreenController.signInAnonymously(context);
    // No hace falta llamar onLoginSuccess() porque dentro
    // de signInAnonymously ya navega al siguiente screen.
  } catch (e) {
    print('Error al iniciar como invitado: $e');
    // Quizás mostrar _showErrorDialog(context, '…');
  } finally {
    setState(() => isLoadingAnonymous = false);
  }
}


  void _launchDeleteAccountURL() async {
    const url = 'https://manitosxpress.com/#/DeleteAccount';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
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
                  color: Color(0xFF841813),
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
                  style: MyTextStyles.drawerButtonTextStyle6,
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
                style: MyTextStyles.linkTextStyle,
              ),
            ),
          ],
        );
      },
    );
  }

  void _launchTermsAndConditionsUrl() async {
    const url =
        'https://manitoxpress-cf855.web.app/#/PrivacyPage'; // URL de tus términos y condiciones
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se pudo abrir el enlace: $url';
    }
  }

  Widget _buildLoginButton({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 0.85.sw,
      height: 55.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(icon, color: iconColor, size: 26.sp),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Distribuir elementos
          children: [
            // Texto en la parte izquierda
            Text(
              'ManitoXpress',
              style: MyTextStyles.buttonTextStyle,
            ),
            // Logo en la parte derecha
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w),
                constraints: BoxConstraints(maxWidth: 0.22.sw),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  width: 0.22.sw,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 1.sw,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 10.h),
                if (_teddyArtboard != null)
                  SizedBox(
                    width: 0.8.sw,
                    height: 0.38.sh,
                    child: rive.Rive(
                      artboard: _teddyArtboard!,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                SizedBox(height: 5.h),
                Text(
                  'Bienvenidos a',
                  style: GoogleFonts.lato(
                    fontSize: 20.sp,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Manitos Xpress',
                  style: MyTextStyles.welcomeTotheJungle1.copyWith(
                    fontSize: 32.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Inicia sesión para continuar',
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 35.h),
                // Botón de Google
                _buildLoginButton(
                  title: 'Continuar con Google',
                  icon: FontAwesomeIcons.google,
                  iconColor: Color(0xFF841813),
                  backgroundColor: Colors.white,
                  textColor: Color(0xFF841813),
                  borderColor: Color(0xFF841813),
                  isLoading: isLoadingGoogle,
                  onPressed: signInWithGoogle,
                ),
                SizedBox(height: 15.h), 
                // Botón de Apple
                _buildLoginButton(
                  title: 'Continuar con Apple',
                  icon: FontAwesomeIcons.apple,
                  iconColor: Colors.white,
                  backgroundColor: Color(0xFF841813),
                  textColor: Colors.white,
                  borderColor: Color(0xFF841813),
                  isLoading: isLoadingApple,
                  onPressed: signInWithApple,
                ),
                SizedBox(height: 15.h), 
                // Botón Invitado
                _buildLoginButton(
                  title: 'Ingresar como Invitado',
                  icon: Icons.person_outline,
                  iconColor: Colors.grey[700]!,
                  backgroundColor: Colors.white,
                  textColor: Colors.grey[800]!,
                  borderColor: Colors.grey[400]!,
                  isLoading: isLoadingAnonymous,
                  onPressed: _signInAsGuest,
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
