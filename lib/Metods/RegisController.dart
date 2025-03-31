import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wizard/flutter_wizard.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
class RegistrationController {
  RegistrationData registrationData = RegistrationData(
    userId: '',
    displayName: '',
    idCardNumber: '',
    phoneNumber: '',
    imagePath: '',
    location: {},
    paymentType: '',
    expertises: [],
    idDocumentImagePath: '',
    email: '',
    imagePathList: [],
    idDocumentImagePath2: '',
    criminalRecordImagePath: '',
    certificateImagePaths: '',
    expLevel: [],
    selectedCountryCode: '',
    devicesId: '',
    fcmToken: '', referralCode: '', points: 0, codeReferral: '', verificationStatus: '',);
  TextEditingController displayNameController = TextEditingController();
  TextEditingController idDocumentController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();


  // Asegúrate de inicializarla con un valor predeterminado si es necesario

  late String imagePath;

  LatLng? location;

  void nextStep() {
    // Implementa la lógica para avanzar al siguiente paso del registro.
    // Puedes realizar validaciones u otras acciones necesarias aquí.
  }

  void completeRegistration() {
    // Implementa la lógica para completar el registro.
    // Accede a los datos almacenados en registrationData y envíalos al backend u otras acciones necesarias.

    // Aquí puedes llamar a un servicio que envíe los datos al backend
    // por ejemplo, registrationService.completeRegistration(registrationData);

    // Después de enviar los datos, puedes realizar otras acciones como navegar a la página de inicio.
  }


  void updateRegistrationData({
    String? displayName,
    String? idCardNumber,
    String? phoneNumber,
    String? imagePath,
    LatLng? location,
    required String workerType,
    required String idDocumentImagePath,
    required String idDocumentImagePath2,
    required String certificateImagePaths,
    required String criminalRecordImagePath, required String referralCode,
  }) {
    if (displayName != null) registrationData.displayName = displayName;
    if (idCardNumber != null) registrationData.idCardNumber = idCardNumber;
    if (phoneNumber != null) registrationData.phoneNumber = phoneNumber;

    // Validar y actualizar imagePath
    if (imagePath != null && imagePath.isNotEmpty) {
      registrationData.imagePath = imagePath;
    } else {
      registrationData.imagePath = ''; // O asignar una ruta predeterminada
    }

    if (location != null) {
      registrationData.location = {
        'lat': location.latitude,
        'lng': location.longitude,
      };
    }
  }
}
class RegistrationData {
  String devicesId;
  String fcmToken;
  String userId;
  String displayName;
  String idCardNumber;
  String phoneNumber;
  String paymentType;
  String selectedCountryCode;
  List<String> imagePathList;
  String idDocumentImagePath;
  String idDocumentImagePath2;
  String criminalRecordImagePath;
  String certificateImagePaths;
  List<Expertise> expertises; // Lista de Expertise
  List<String> expLevel;
  String imagePath;
  Map<String, double?>? location;
  String email;
  String referralCode; // Código de referido
  int points; // Puntos
  String codeReferral; // Código generado
  String verificationStatus; // Nuevo campo añadido

  RegistrationData.fromForm({
    required String devicesId,
    required String fcmToken,
    required String userId,
    required String displayName,
    required String idCardNumber,
    required String phoneNumber,
    required String paymentType,
    required String selectedCountryCode,
    required List<String> imagePathList,
    required String idDocumentImagePath,
    required String idDocumentImagePath2,
    required String criminalRecordImagePath,
    required String certificateImagePaths,
    required List<Expertise> expertises,
    required List<String> expLevel,
    required String imagePath,
    required Map<String, double?>? location,
    required String email,
    required String referralCode,
    required int points,
    required String codeReferral,
    required String verificationStatus, // Añadido aquí
  }) : verificationStatus = verificationStatus, // Asegúrate de incluirlo en el constructor
        userId = userId,
        fcmToken = fcmToken,
        devicesId = devicesId,
        displayName = displayName,
        idCardNumber = idCardNumber,
        phoneNumber = phoneNumber,
        imagePathList = imagePathList,
        imagePath = imagePath,
        paymentType = paymentType,
        expertises = expertises,
        selectedCountryCode = selectedCountryCode,
        expLevel = expLevel,
        idDocumentImagePath = idDocumentImagePath,
        idDocumentImagePath2 = idDocumentImagePath2,
        criminalRecordImagePath = criminalRecordImagePath,
        certificateImagePaths = certificateImagePaths,
        email = email,
        location = location,
        referralCode = referralCode,
        points = points,
        codeReferral = '${displayName.split(' ').first}_${idCardNumber.length >= 4 ? idCardNumber.substring(idCardNumber.length - 4) : idCardNumber}';

  RegistrationData({
    required this.devicesId,
    required this.fcmToken,
    required this.userId,
    required this.displayName,
    required this.idCardNumber,
    required this.phoneNumber,
    required this.imagePath,
    required this.imagePathList,
    required this.paymentType,
    required this.selectedCountryCode,
    required this.idDocumentImagePath,
    required this.idDocumentImagePath2,
    required this.criminalRecordImagePath,
    required this.certificateImagePaths,
    required this.expertises,
    required this.expLevel,
    required this.email,
    required this.location,
    required this.referralCode,
    required this.points,
    required this.codeReferral,
    required this.verificationStatus, // Asegúrate de incluir este campo también
  });
}