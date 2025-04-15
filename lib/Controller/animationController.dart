import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socio/Controller/RegisController.dart';
import 'package:socio/Screens/Home.dart';


import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';

class EstrellaController {
  static void handsOnTheEyes(SMIBool? isHandsUp) {
    isHandsUp?.change(true);
  }

  static void lookOnTheTextField(
      SMIBool? isHandsUp, SMIBool? isChecking, SMINumber? numLook) {
    isHandsUp?.change(false);
    isChecking?.change(false);
    numLook?.change(0);
  }

  static void moveEyeBalls(SMINumber? numLook, String val) {
    numLook?.change(val.length.toDouble());
  }

  static void lookAtTapPosition(SMIBool? isHandsUp, SMIBool? isChecking,
      SMINumber? numLook, TextEditingController? textEditingController) {
    isHandsUp?.change(false);
    isChecking?.change(true);

    final cursorPosition = textEditingController?.selection.base.offset ?? 0;
    const totalZones = 4;
    final zoneWidth = textEditingController!.text.length / totalZones;
    final targetZone = (cursorPosition / zoneWidth).ceil();

    numLook?.change(targetZone.toDouble());
  }

  static Future<void> login(
      BuildContext context,
      TextEditingController emailController,
      TextEditingController passwordController) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    SMITrigger? failTrigger;

    try {
      final email = emailController.text;
      final password = passwordController.text;

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        if (user.emailVerified) {
          final userData = await fetchUserData(user.uid); // Obtén los datos del usuario
          final registrationData = userData.registrationData;

          _navigateToHomePage(context, userData, registrationData);
        } else {
          failTrigger?.fire();
          _showFailedLoginDialog(context, "Por favor, verifica tu correo electrónico.");
          await _auth.signOut();
        }
      } else {
        failTrigger?.fire();
        _showFailedLoginDialog(context, "Email o contraseña incorrectos.");
      }
    } catch (e) {
      failTrigger?.fire();
      print("Error al iniciar sesión: $e");
      _showFailedLoginDialog(context, "Error al iniciar sesión. Inténtalo de nuevo.");
    }
  }

  static void _showFailedLoginDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Inicio de sesión fallido"),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("Aceptar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> _navigateToHomePage(BuildContext context, UserData userData, RegistrationData registrationData) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          userData: userData,
          registrationData: registrationData,
        ),
      ),
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
    displayName: 'John Doe',
    idCardNumber: '123456789',
    phoneNumber: '555-1234',
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
    email: 'john.doe@example.com',
    registrationData: RegistrationData(
      userId: userId,
      devicesId: '',
      fcmToken: '',
      displayName: 'John Doe',
      idCardNumber: '123456789',
      phoneNumber: '555-1234',
      paymentType: '',
      expertises: [],
      expLevel: [],
      selectedCountryCode: '',
      imagePath: '',
      location: null,
      idDocumentImagePath: '',
      idDocumentImagePath2: '',
      email: 'john.doe@example.com',
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