import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wizard/flutter_wizard.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/wizards/Certificates.dart';
import 'package:socio/wizards/CriminalRecords.dart';
import 'package:socio/wizards/DocumentB.dart';
import 'package:socio/wizards/IdDocument.dart';
import 'package:socio/wizards/ProfileImage.dart';

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
    fcmToken: '',);
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
    required String criminalRecordImagePath,
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
  List<Expertise> expertises; // Cambiado a lista de Expertise
  List<String> expLevel;
  String imagePath;
  Map<String, double?>? location;
  String email;

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
    required List<Expertise> expertises, // Cambiado a lista de Expertise
    required List<String> expLevel,
    required String imagePath,
    required Map<String, double?>? location,
    required String email,
  })  : userId = userId,
        fcmToken = fcmToken,
        devicesId = devicesId,
        displayName = displayName,
        idCardNumber = idCardNumber,
        phoneNumber = phoneNumber,
        imagePathList = imagePathList,
        imagePath = imagePath,
        paymentType = paymentType,
        expertises = expertises, // Cambiado a lista de Expertise
        selectedCountryCode = selectedCountryCode,
        expLevel = expLevel,
        idDocumentImagePath = idDocumentImagePath,
        idDocumentImagePath2 = idDocumentImagePath2,
        criminalRecordImagePath = criminalRecordImagePath,
        certificateImagePaths = certificateImagePaths,
        email = email,
        location = location;

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
    required this.expertises, // Cambiado a lista de Expertise
    required this.expLevel,
    required this.email,
    required this.location,
  });

  void setImages(List<String> newImagePaths) {
    imagePath = newImagePaths.join(","); // Un ejemplo de cómo podrías unir las rutas
  }
}