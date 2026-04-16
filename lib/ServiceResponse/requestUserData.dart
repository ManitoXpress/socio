import 'package:firebase_auth/firebase_auth.dart';
import 'package:socio/controllers/RegisController.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
class UserData {
  String userId;
  String displayName;
  String idCardNumber;
  String phoneNumber;
  final String? getToken;
  String imagePath;
  String pdfPathController;
  String criminalRecordImagePath;
  String idDocumentImagePath;
  String idDocumentImagePath2;
  String medicalLicenseImagePath;
  String professionalTitleImagePath;
  String selectedCountryCode;
  List<Expertise> expertises;
  List<String> expLevel;
  List<String> certificateImagePaths;        // Cambiado a List<String>
  Map<String, double?>? location;
  String paymentType;
  String email;
  RegistrationData registrationData;
  String referrerWorkerId;
  String referralCode;
  String verificationStatus;
  int points;
  String? requiresInvoice;

  UserData({
    required this.userId,
    required this.displayName,
    required this.idCardNumber,
    required this.phoneNumber,
    this.getToken,
    required this.imagePath,
    required this.pdfPathController,
    required this.criminalRecordImagePath,
    required this.idDocumentImagePath,
    required this.idDocumentImagePath2,
    required this.medicalLicenseImagePath,
    required this.professionalTitleImagePath,
    required this.selectedCountryCode,
    required this.expertises,
    required this.expLevel,
    required this.certificateImagePaths,     // constructor actualizado
    this.location,
    required this.paymentType,
    required this.email,
    required this.registrationData,
    required this.referrerWorkerId,
    required this.referralCode,
    required this.verificationStatus,
    required this.points,
    this.requiresInvoice,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    // Convertir certificateImagePaths de dynamic a List<String>
    List<String> certPaths = [];
    final rawCerts = json['certificateImagePaths'];
    if (rawCerts is String) {
      certPaths = rawCerts.split(',').map((s) => s.trim()).toList();
    } else if (rawCerts is List) {
      certPaths = rawCerts.whereType<String>().toList();
    }

    return UserData(
      userId: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      imagePath: json['imagePath'] ?? '',
      getToken: json['getToken'],
      pdfPathController: json['pdfPathController'] ?? '',
      criminalRecordImagePath: json['criminalRecordImagePath'] ?? '',
      paymentType: json['paymentType'] ?? '',
      selectedCountryCode: json['selectedCountryCode'] ?? '',
      expertises: _convertToExpertisesList(json['expertises']),
      expLevel: _convertToList(json['expLevel']),
      certificateImagePaths: certPaths,    // uso de la lista procesada
      idCardNumber: json['idCardNumber'] ?? '',
      location: json['location'] != null
          ? Map<String, double?>.from(json['location'])
          : null,
      idDocumentImagePath: json['idDocumentImagePath'] ?? '',
      idDocumentImagePath2: json['idDocumentImagePath2'] ?? '',
      medicalLicenseImagePath: json['medicalLicenseImagePath'] ?? '',
      professionalTitleImagePath: json['professionalTitleImagePath'] ?? '',
      referrerWorkerId: json['referrerWorkerId'] ?? '',
      referralCode: json['referralCode'] ?? '',
      verificationStatus: json['verificationStatus'] ?? '',
      requiresInvoice: json['requiresInvoice'],
      points: json['points'] is int
          ? json['points']
          : int.tryParse(json['points'].toString()) ?? 0,
      registrationData: RegistrationData(
        userId: json['id'] ?? '',
        devicesId: json['devicesId'] ?? '',
        fcmToken: json['fcmToken'] ?? '',
        displayName: json['displayName'] ?? '',
        idCardNumber: json['idCardNumber'] ?? '',
        phoneNumber: json['phoneNumber'] ?? '',
        paymentType: json['paymentType'] ?? '',
        expertises: _convertToExpertisesList(json['expertises']),
        expLevel: _convertToList(json['expLevel']),
        selectedCountryCode: json['selectedCountryCode'] ?? '',
        imagePath: json['imagePath'] ?? '',
        location: json['location'] != null
            ? Map<String, double?>.from(json['location'])
            : {},
        idDocumentImagePath: json['idDocumentImagePath'] ?? '',
        idDocumentImagePath2: json['idDocumentImagePath2'] ?? '',
        email: json['email'] ?? '',
        imagePathList: [],
        criminalRecordImagePath: json['criminalRecordImagePath'] ?? '',
        certificateImagePaths: _convertToList(json['certificateImagePaths']),
        referralCode: json['referralCode'] ?? '',
        codeReferral: json['codeReferral'] ?? '',
        verificationStatus: json['verificationStatus'] ?? '',
        points: json['points'] is int
            ? json['points']
            : int.tryParse(json['points'].toString()) ?? 0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'imagePath': imagePath,
      'getToken': getToken,
      'pdfPathController': pdfPathController,
      'criminalRecordImagePath': criminalRecordImagePath,
      'paymentType': paymentType,
      'selectedCountryCode': selectedCountryCode,
      'expertises': expertises.map((e) => e.toMap()).toList(),
      'expLevel': expLevel,
      'certificateImagePaths': certificateImagePaths, // Lista directamente
      'idCardNumber': idCardNumber,
      'location': location,
      'idDocumentImagePath': idDocumentImagePath,
      'idDocumentImagePath2': idDocumentImagePath2,
      'referrerWorkerId': referrerWorkerId,
      'referralCode': referralCode,
      'verificationStatus': verificationStatus,
      'points': points,
      'requiresInvoice': requiresInvoice,
    };
  }

  static List<String> _convertToList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  static List<Expertise> _convertToExpertisesList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((item) => Expertise.fromMap(item)).toList();
    }
    return [];
  }
}

// Función extra que ya tenías:
Future<String?> getCurrentWorkerId() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    return user.uid;
  } else {
    return null;
  }
}