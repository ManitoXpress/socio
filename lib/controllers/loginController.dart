import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:socio/menu/welcome.dart';

import '../Screens/Home.dart';
import '../ServiceResponse/post.dart';
import 'RegisController.dart';


import '../ServiceResponse/requestUserData.dart';
class LoginScreenController {
  static final ApiService apiService = ApiService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tokenCollection = 'user_tokens';

  // Almacena datos del usuario en Firestore si no existen
  static Future<void> storeUserData(User user) async {
    final userRef = _firestore.collection('workers').doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'displayName': user.displayName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'imagePath': user.photoURL,
      });
    }
  }

  // Obtiene o crea un token para el usuario
  static Future<String?> getToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final existingToken = await _getExistingToken(user.uid);
        if (existingToken != null) {
          return existingToken;
        }
        final newToken = await user.getIdToken();
        if (newToken != null) {
          await _storeToken(user.uid, newToken);
        }
        return newToken;
      }
      print('El usuario no está autenticado.');
      return null;
    } catch (e) {
      print('Error al obtener el token: $e');
      return null;
    }
  }

  static Future<String?> _getExistingToken(String userId) async {
    try {
      final tokenDoc = await _firestore.collection(_tokenCollection).doc(userId).get();
      if (tokenDoc.exists) {
        return tokenDoc['token'] as String?;
      }
      return null;
    } catch (e) {
      print('Error al obtener el token existente: $e');
      return null;
    }
  }

  static Future<void> _storeToken(String userId, String newToken) async {
    try {
      await _firestore.collection(_tokenCollection).doc(userId).set({'token': newToken});
    } catch (e) {
      print('Error al almacenar el token: $e');
    }
  }

  // Verifica si el usuario ya está registrado
  static Future<bool> _checkIfUserIsRegistered(String userId) async {
    try {
      final userDoc = await _firestore.collection('workers').doc(userId).get();
      return userDoc.exists;
    } catch (e) {
      print('Error al verificar el registro del usuario: $e');
      return false;
    }
  }

  // Navegación según el estado del usuario
static Future<void> _navigateToRegisterScreen(BuildContext context, {bool alreadyRegistered = false}) async {
  final registrationController = RegistrationController();
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    // Si no hay usuario autenticado, podrías redirigir a login o lanzar un error
    return;
  }

  final userData = await fetchUserData(user.uid); // Obtener datos del usuario

  if (alreadyRegistered) {
    final registrationData = userData.registrationData;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          registrationData: registrationData,
          userData: userData,
        ),
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FirstTimeLoginScreen(
          registrationController: registrationController,
          userData: userData, // 👉 Pasar userData también aquí
        ),
      ),
    );
  }
}


  static Future<void> _updateLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  // Inicio de sesión con Apple
  static Future<void> signInWithApple(BuildContext context) async {
    try {
      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ],
      );
      final oAuth = OAuthProvider("apple.com").credential(
        idToken: appleCred.identityToken,
        accessToken: appleCred.authorizationCode,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(oAuth);
      final user = result.user!;
      final alreadyRegistered = await _checkIfUserIsRegistered(user.uid);
      await storeUserData(user);
      // Guardar flag de sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      // Guardar token FCM en Firestore
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      await FirebaseFirestore.instance.collection('workers').doc(user.uid).set({
        'fcmToken': fcmToken,
      }, SetOptions(merge: true));
      await _navigateToRegisterScreen(context,
          alreadyRegistered: alreadyRegistered);
    } catch (e) {
      _showErrorDialog(
          context, 'No se pudo iniciar sesión con Apple. Inténtelo de nuevo.');
    }
  }
   static Future<void> signInAnonymously(BuildContext context) async {
  try {
    final authResult = await FirebaseAuth.instance.signInAnonymously();
    final user = authResult.user;
    if (user == null) return;

    // (Opcional) Si quieres mantener hospedado un UserData mínimo, créalo aquí.
    final userData = UserData(
      userId: user.uid,
      displayName: '',
      email: '',
      phoneNumber: '',
      location: {},
      paymentType: '',
      selectedCountryCode: '',
      registrationData: RegistrationData(
        userId: user.uid,
        displayName: '',
        devicesId: '',
        fcmToken: '',
        phoneNumber: '',
        paymentType: '',
        selectedCountryCode: '',
        email: '',
        location: {},
        points: 0,
        idCardNumber: '',
        imagePath: '',
        imagePathList: [],
        idDocumentImagePath: '',
        idDocumentImagePath2: '',
        criminalRecordImagePath: '',
        certificateImagePaths: [],
        expertises: [],
        expLevel: [],
        referralCode: '',
        codeReferral: '',
        verificationStatus: '',
      ),
      getToken: '',
      referralCode: '',
      points: 0,
      idCardNumber: '',
      imagePath: '',
      pdfPathController: '',
      criminalRecordImagePath: '',
      idDocumentImagePath: '',
      idDocumentImagePath2: '',
      medicalLicenseImagePath: '',
      professionalTitleImagePath: '',
      expertises: [],
      expLevel: [],
      certificateImagePaths: [],
      referrerWorkerId: '',
      verificationStatus: '',
    );

    // Guarda en Firestore si lo necesitas
    await storeUserData(user);
    // Aquí puedes guardar el userData en tu base de datos Firestore si es necesario
    await _updateLoginState(true);

    // Ahora indicamos que YA está “registrado”
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          userData: userData,
          registrationData: userData.registrationData,
          isGuest: true,            // ← aquí
        ),
      ),
    );

  } catch (e) {
    print('Error durante el inicio de sesión anónima: $e');
    _showErrorDialog(context, 'No se pudo iniciar sesión como invitado.');
  }
}

  // Inicio de sesión con Google
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // ⚡ FUNDAMENTAL: Limpia sesiones "colgadas" (evita que se quede en blanco en iOS)
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      
      final googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final googleAuth = await googleSignInAccount.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final authResult = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = authResult.user;

        if (user != null) {
          final alreadyRegistered = await _checkIfUserIsRegistered(user.uid);
          await storeUserData(user);

          // Guardar token FCM en Firestore
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await FirebaseFirestore.instance.collection('workers').doc(user.uid).set({
              'fcmToken': fcmToken,
            }, SetOptions(merge: true));
          }

          await _updateLoginState(true); // Siempre logeado

          print('Inicio de sesión con Google exitoso para ${user.displayName}');
          await _navigateToRegisterScreen(
              context,
              alreadyRegistered: alreadyRegistered
          );
        }
      }
    } catch (e) {
      final errorStr = e.toString();
      if (!errorStr.contains('sign_in_canceled') &&
          !errorStr.contains('canceled') &&
          !errorStr.contains('network_error')) {
        print('Error durante el inicio de sesión con Google: $e');
        if (context.mounted) {
          _showErrorDialog(context, 'No se pudo iniciar sesión con Google. Inténtelo de nuevo.');
        }
      }
    }
  }

  // Inicio de sesión con email y contraseña
  Future<User?> login(BuildContext context, String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        if (user.emailVerified) {
          await storeUserData(user);
          await _navigateToRegisterScreen(context, alreadyRegistered: true);
          return user;
        } else {
          _showErrorDialog(context, 'Por favor, verifica tu correo electrónico.');
          await FirebaseAuth.instance.signOut();
        }
      }
    } catch (e) {
      print('Error al iniciar sesión: $e');
      _showErrorDialog(context, 'Email o contraseña incorrectos.');
    }
    return null;
  }

  // Mostrar error en diálogo
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
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
    medicalLicenseImagePath: '',
    professionalTitleImagePath: '',
    selectedCountryCode: '',
    expertises: [],
    expLevel: [],
    certificateImagePaths: [],
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
      certificateImagePaths: [],
      referralCode: '',
      points: 0,
      codeReferral: '', verificationStatus: '',
    ),
    referrerWorkerId: '',
    referralCode: '',
    points: 0, verificationStatus: '',
  );
}