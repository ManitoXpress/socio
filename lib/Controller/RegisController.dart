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
    String? requiresInvoice, // Nuevo campo agregado
    required String workerType,
    required String idDocumentImagePath,
    required String idDocumentImagePath2,
    required String certificateImagePaths,
    required String medicalLicenseImagePath,
    required String professionalTitleImagePath,
    required String jobCompletePath,
    required String criminalRecordImagePath, required String referralCode, required List<String> jobCompletePaths,
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

  // Nuevos campos para Salud
  String medicalLicenseImagePath;
  String professionalTitleImagePath;

  List<Expertise> expertises;
  List<String> expLevel;
  String imagePath;

  /// Ubicación tanto en Map como en campos discretos
  Map<String, double?>? location;
  double? latitude;
  double? longitude;
  String? address;

  /// Favoritos e información extra
  bool? isFavorite;
  String? additionalInfo;

  String email;
  String referralCode;
  int points;
  String codeReferral;
  String verificationStatus;
  String? requiresInvoice;

  /// Constructor principal
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
    this.medicalLicenseImagePath = '',
    this.professionalTitleImagePath = '',
    required this.expertises,
    required this.expLevel,
    required this.email,
    required this.location,
    required this.referralCode,
    required this.points,
    required this.codeReferral,
    required this.verificationStatus,
    this.requiresInvoice,
  }) {
    // Derivar latitud/longitud
    latitude = location?['lat'];
    longitude = location?['lng'];
    // Inicializar opcionales
    address = null;
    isFavorite = false;
    additionalInfo = null;
  }

  /// Constructor para enviar al servidor (desde formulario)
  RegistrationData.fromForm({
    required this.devicesId,
    required this.fcmToken,
    required this.userId,
    required this.displayName,
    required this.idCardNumber,
    required this.phoneNumber,
    required this.paymentType,
    required this.selectedCountryCode,
    required this.imagePathList,
    required this.idDocumentImagePath,
    required this.idDocumentImagePath2,
    required this.criminalRecordImagePath,
    required this.certificateImagePaths,
    this.medicalLicenseImagePath = '',
    this.professionalTitleImagePath = '',
    required this.expertises,
    required this.expLevel,
    required this.imagePath,
    required this.location,
    this.requiresInvoice,
    required this.email,
    required this.referralCode,
    required this.points,
    required this.codeReferral,
    required this.verificationStatus,
  }) {
    // Derivar latitud/longitud
    latitude = location?['lat'];
    longitude = location?['lng'];
    // Inicializar opcionales
    address = null;
    isFavorite = false;
    additionalInfo = null;
  }

  /// Constructor para invitado
  factory RegistrationData.guest() {
    return RegistrationData(
      devicesId: '',
      fcmToken: '',
      userId: 'guest',
      displayName: 'Invitado',
      idCardNumber: '',
      phoneNumber: '',
      imagePath: 'assets/images/guest_placeholder.png',
      imagePathList: [],
      paymentType: '',
      selectedCountryCode: '',
      idDocumentImagePath: '',
      idDocumentImagePath2: '',
      criminalRecordImagePath: '',
      certificateImagePaths: '',
      medicalLicenseImagePath: '',
      professionalTitleImagePath: '',
      expertises: [],
      expLevel: [],
      email: '',
      location: null,
      referralCode: '',
      points: 0,
      codeReferral: 'Invitado',
      verificationStatus: 'Invitado',
    );
  }
}
