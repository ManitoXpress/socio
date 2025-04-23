import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socio/Controller/RegisController.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';


class RegistrationProvider extends ChangeNotifier {
  final RegistrationController registrationController;
  final VoidCallback completeRegistrationCallback;
  final ApiService apiService;

  int currentStep = 0;
  late RegistrationData registrationData;
  late UserData userData;
  LatLng? location;
  String? fcmToken;
  bool loading = false;

  RegistrationProvider({
    required this.registrationController,
    required this.completeRegistrationCallback,
    required this.apiService,
  }) {
    _initialize();
  }

  Future<void> _initialize() async {
    fcmToken = await FirebaseMessaging.instance.getToken();
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? '';

    registrationData = RegistrationData(
      userId: user?.uid ?? '',
      displayName: displayName,
      devicesId: '',
      fcmToken: fcmToken ?? '',
      idCardNumber: '',
      phoneNumber: '',
      imagePath: '',
      imagePathList: [],
      paymentType: '',
      selectedCountryCode: '',
      idDocumentImagePath: '',
      idDocumentImagePath2: '',
      criminalRecordImagePath: '',
      certificateImagePaths: '',
      expertises: [],
      expLevel: [],
      email: user?.email ?? '',
      location: {'lat': 0.0, 'lng': 0.0},
      referralCode: '',
      points: 0,
      codeReferral: '',
      verificationStatus: '',
    );

    location = LatLng(
      registrationData.location?['lat'] ?? 0.0,
      registrationData.location?['lng'] ?? 0.0,
    );

    userData = UserData(
      userId: registrationData.userId,
      displayName: displayName,
      registrationData: registrationData,
      idCardNumber: registrationData.idCardNumber,
      phoneNumber: registrationData.phoneNumber,
      imagePath: registrationData.imagePath,
      pdfPathController: '',
      criminalRecordImagePath: registrationData.criminalRecordImagePath,
      idDocumentImagePath: registrationData.idDocumentImagePath,
      idDocumentImagePath2: registrationData.idDocumentImagePath2,
      selectedCountryCode: registrationData.selectedCountryCode,
      expertises: registrationData.expertises,
      expLevel: registrationData.expLevel,
      certificateImagePaths: registrationData.certificateImagePaths,
      paymentType: registrationData.paymentType,
      email: registrationData.email,
      referrerWorkerId: '',
      referralCode: registrationData.referralCode,
      verificationStatus: registrationData.verificationStatus,
      points: registrationData.points,
    );

    notifyListeners();
  }

  void nextStep() {
    // Validaciones...
    if (currentStep < 7) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void setLocation(LatLng loc) {
    location = loc;
    registrationData.location = {'lat': loc.latitude, 'lng': loc.longitude};
    notifyListeners();
  }

  /// Comprime y redimensiona usando package:image antes de subir
  Future<File> compressAndResizeImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return file;
    // Resize a width 800px manteniendo relación de aspecto
    final resized = img.copyResize(image, width: 800);
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_cmp.jpg';
    final jpg = img.encodeJpg(resized, quality: 85);
    final compressedFile = File(targetPath)..writeAsBytesSync(jpg);
    return compressedFile;
  }

  /// Helper genérico para comprimir (si es imagen) y subir,
  /// luego asignar la URL resultante a registrationData.
  Future<void> _uploadAndSetUrl({
    required String localPath,
    required Future<String> Function(File, String) uploadFn,
    required void Function(String) setUrl,
    required String uid,
  }) async {
    if (localPath.isEmpty) return;
    final file = File(localPath);
    if (!file.existsSync()) return;
    try {
      // Comprimir + redimensionar
      final compressed = await compressAndResizeImage(file);
      final url = await uploadFn(compressed, uid);
      if (url.isNotEmpty) setUrl(url);
    } catch (e) {
      debugPrint('Error subiendo $localPath: $e');
    }
  }

  Future<void> completeRegistration() async {
    loading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');
      final uid = user.uid;

      // Actualizar campos antes de subir
      registrationData
        ..userId = uid
        ..location = {
          'lat': location?.latitude ?? 0.0,
          'lng': location?.longitude ?? 0.0,
        }
        ..expertises = userData.expertises
        ..expLevel = userData.expLevel
        ..paymentType = userData.paymentType
        ..phoneNumber = userData.phoneNumber
        ..referralCode = userData.referralCode;

      // Subida de imágenes
      await _uploadAndSetUrl(
        localPath: registrationData.imagePath,
        uploadFn: apiService.uploadImageToFirebaseStorage,
        setUrl: (u) => registrationData.imagePath = u,
        uid: uid,
      );
      await _uploadAndSetUrl(
        localPath: registrationData.idDocumentImagePath,
        uploadFn: apiService.uploadImageToFirebaseStorage2,
        setUrl: (u) => registrationData.idDocumentImagePath = u,
        uid: uid,
      );
      await _uploadAndSetUrl(
        localPath: registrationData.idDocumentImagePath2,
        uploadFn: apiService.uploadImageToFirebaseStorage3,
        setUrl: (u) => registrationData.idDocumentImagePath2 = u,
        uid: uid,
      );
      await _uploadAndSetUrl(
        localPath: registrationData.certificateImagePaths,
        uploadFn: apiService.uploadImageToFirebaseStorage4,
        setUrl: (u) => registrationData.certificateImagePaths = u,
        uid: uid,
      );

      // Subida de PDF de antecedentes penales (sin compresión)
      if (registrationData.criminalRecordImagePath.isNotEmpty) {
        final pdfFile = File(registrationData.criminalRecordImagePath);
        if (pdfFile.existsSync()) {
          try {
            final pdfUrl = await apiService.uploadImageToFirebaseStorage5(pdfFile, uid);
            if (pdfUrl.isNotEmpty) {
              registrationData.criminalRecordImagePath = pdfUrl;
            }
          } catch (e) {
            debugPrint('Error subiendo PDF criminal: $e');
          }
        }
      }

      // Incrementar puntos al referrer en Firestore
      if (userData.referralCode.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('workers')
            .doc(userData.referralCode)
            .update({ 'points': FieldValue.increment(1) });
      }

      // Obtener puntos actualizados del usuario actual
      final doc = await FirebaseFirestore.instance.collection('workers').doc(uid).get();
      registrationData.points = doc.data()?['points'] ?? 0;

      // Llamada final a API
      final token = await user.getIdToken();
      final response = await apiService.updateUser(uid, registrationData, token!);

      if (response.statusCode == 200) {
        completeRegistrationCallback();
      } else {
        throw Exception('Error en servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en completeRegistration: $e');
      // Aquí podrías exponer un error al UI si lo necesitas
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
