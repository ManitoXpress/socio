import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socio/Controller/RegisController.dart';
import 'package:socio/Screens/Home.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';

class RegistrationProvider extends ChangeNotifier {
  final RegistrationController registrationController;
  final VoidCallback completeRegistrationCallback; // si aún lo usas
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
    // Inicializa con datos vacíos
    registrationData = RegistrationData(
      userId: '',
      displayName: '',
      devicesId: '',
      fcmToken: '',
      idCardNumber: '',
      phoneNumber: '',
      imagePath: '',
      imagePathList: [],
      paymentType: '',
      selectedCountryCode: '',
      medicalLicenseImagePath: '',
      professionalTitleImagePath: '',
      idDocumentImagePath: '',
      idDocumentImagePath2: '',
      criminalRecordImagePath: '',
      certificateImagePaths: [],
      expertises: [],
      expLevel: [],
      email: '',
      location: {'lat': 0.0, 'lng': 0.0},
      referralCode: '',
      points: 0,
      codeReferral: '',
      verificationStatus: '',
    );
    userData = UserData(
      userId: '',
      displayName: '',
      registrationData: registrationData,
      idCardNumber: '',
      phoneNumber: '',
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
      paymentType: '',
      email: '',
      referrerWorkerId: '',
      referralCode: '',
      points: 0,
      verificationStatus: '',
    );

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
      medicalLicenseImagePath: '',
      professionalTitleImagePath: '',
      idDocumentImagePath: '',
      idDocumentImagePath2: '',
      criminalRecordImagePath: '',
      certificateImagePaths: [],
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
      medicalLicenseImagePath: registrationData.medicalLicenseImagePath,
      professionalTitleImagePath: registrationData.professionalTitleImagePath,
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

    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void nextStep() {
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

  Future<void> updateProfileImage({
    required String fieldKey,
    required String localPath,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _uploadAndSetUrl(
      localPath: localPath,
      uploadFn: apiService.uploadImageToFirebaseStorage,
      setUrl: (url) {
        switch (fieldKey) {
          case 'profile':
            registrationData.imagePath = url;
            break;
          case 'idFront':
            registrationData.idDocumentImagePath = url;
            break;
          case 'idBack':
            registrationData.idDocumentImagePath2 = url;
            break;
          case 'certificate':
            registrationData.certificateImagePaths.add(url);
            break;
          case 'criminal':
            registrationData.criminalRecordImagePath = url;
            break;
          case 'medicalLicense':
            registrationData.medicalLicenseImagePath = url;
            break;
          case 'professionalTitle':
            registrationData.professionalTitleImagePath = url;
            break;
          default:
            break;
        }
      },
      uid: user.uid,
    );
    notifyListeners();
  }

  Future<File> compressAndResizeImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return file;
    final resized = img.copyResize(image, width: 800);
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_cmp.jpg';
    final jpg = img.encodeJpg(resized, quality: 85);
    final compressedFile = File(targetPath)..writeAsBytesSync(jpg);
    return compressedFile;
  }

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
      final compressed = await compressAndResizeImage(file);
      final url = await uploadFn(compressed, uid);
      if (url.isNotEmpty) setUrl(url);
    } catch (e) {
      debugPrint('Error subiendo $localPath: $e');
    }
  }

  Future<List<String>> uploadMultipleCertificates(
      List<String> localPaths, String uid) async {
    final List<String> urls = [];
    for (final path in localPaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      try {
        final compressed = await compressAndResizeImage(file);
        final url =
            await apiService.uploadImageToFirebaseStorage4(compressed, uid);
        if (url.isNotEmpty) urls.add(url);
      } catch (e) {
        debugPrint('Error subiendo certificado $path: $e');
      }
    }
    return urls;
  }

  Future<void> completeRegistration(BuildContext context) async {
    loading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');
      final uid = user.uid;

      // Actualizar datos básicos
      registrationData
        ..userId = uid
        ..location = {
          'lat': location?.latitude ?? 0.0,
          'lng': location?.longitude ?? 0.0
        }
        ..expertises = userData.expertises
        ..expLevel = userData.expLevel
        ..paymentType = registrationData.paymentType
        ..phoneNumber = registrationData.phoneNumber
        ..referralCode = userData.referralCode;

      // Subir imágenes únicas
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

      // Subir múltiples certificados
      final uploadedCertUrls = await uploadMultipleCertificates(
        registrationData.certificateImagePaths,
        uid,
      );
      registrationData.certificateImagePaths = uploadedCertUrls;

      // Subir PDF criminal si existe
      if (registrationData.criminalRecordImagePath.isNotEmpty) {
        final pdfFile = File(registrationData.criminalRecordImagePath);
        if (pdfFile.existsSync()) {
          try {
            final pdfUrl =
                await apiService.uploadImageToFirebaseStorage5(pdfFile, uid);
            if (pdfUrl.isNotEmpty) {
              registrationData.criminalRecordImagePath = pdfUrl;
            }
          } catch (e) {
            debugPrint('Error subiendo PDF criminal: $e');
          }
        }
      }

      // Subir título profesional si existe
      if (registrationData.professionalTitleImagePath.isNotEmpty) {
        final file = File(registrationData.professionalTitleImagePath);
        if (file.existsSync()) {
          final compressed = await compressAndResizeImage(file);
          final titleUrl =
              await apiService.uploadImageToFirebaseStorage4(compressed, uid);
          if (titleUrl.isNotEmpty) {
            registrationData.professionalTitleImagePath = titleUrl;
          }
        }
      }

      // Incrementar puntos al referidor
      if (userData.referrerWorkerId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('workers')
            .doc(userData.referrerWorkerId)
            .update({'points': FieldValue.increment(10)});
      }

      // Obtener puntos actualizados
      final doc =
          await FirebaseFirestore.instance.collection('workers').doc(uid).get();
      registrationData.points = doc.data()?['points'] ?? 0;

      // Llamada final a API
      final token = await user.getIdToken();
      final response =
          await apiService.updateUser(uid, registrationData, token!);

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userData: userData,
              registrationData: registrationData,
            ),
          ),
        );
      } else {
        throw Exception('Error en servidor: \${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en completeRegistration: \$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completando registro: \$e')),
      );
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
