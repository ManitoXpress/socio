import 'package:firebase_auth/firebase_auth.dart';
import 'package:socio/Metods/RegisController.dart';
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
  String selectedCountryCode;
  List<Expertise> expertises;
  List<String> expLevel;
  String certificateImagePaths;
  Map<String, double?>? location;
  String paymentType;
  String email;
  RegistrationData registrationData;
  String referrerWorkerId; // ID del trabajador que refirió
  String referralCode; // Código de referido ingresado por el usuario
  String verificationStatus;
  int points; // Cambiado a int

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
    required this.selectedCountryCode,
    required this.expertises,
    required this.expLevel,
    required this.certificateImagePaths,
    this.location,
    required this.paymentType,
    required this.email,
    required this.registrationData,
    required this.referrerWorkerId,
    required this.referralCode, // Agregamos el campo referralCode
    required this.verificationStatus,
    required this.points, // Agregamos el campo points
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
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
      certificateImagePaths: json['certificateImagePaths'] ?? '',
      idCardNumber: json['idCardNumber'] ?? '',
      location: json['location'] != null
          ? Map<String, double?>.from(json['location'])
          : null,
      idDocumentImagePath: json['idDocumentImagePath'] ?? '',
      idDocumentImagePath2: json['idDocumentImagePath2'] ?? '',
      referrerWorkerId: json['referrerWorkerId'] ?? '', // ID del que refirió
      referralCode: json['referralCode'] ?? '', // Código de referido ingresado
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
            : null,
        idDocumentImagePath: json['idDocumentImagePath'] ?? '',
        idDocumentImagePath2: json['idDocumentImagePath2'] ?? '',
        email: json['email'] ?? '',
        imagePathList: [],
        criminalRecordImagePath: json['criminalRecordImagePath'] ?? '',
        certificateImagePaths: json['certificateImagePaths'] ?? '',
        referralCode: json['referralCode'] ?? '',
        points: json['points'] is int ? json['points'] : int.tryParse(json['points'].toString()) ?? 0, codeReferral: json['codeReferral']?? '', verificationStatus: json['verificationStatus']?? '', // Convierte a int
      ),
      points: json['points'] is int ? json['points'] : int.tryParse(json['points'].toString()) ?? 0, verificationStatus: json['verificationStatus']?? '', // Convierte a int
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
      'certificateImagePaths': certificateImagePaths,
      'idCardNumber': idCardNumber,
      'location': location,
      'idDocumentImagePath': idDocumentImagePath,
      'idDocumentImagePath2': idDocumentImagePath2,
      'referrerWorkerId': referrerWorkerId,
      'referralCode': referralCode,
      'points': points, // Asegúrate de incluir points
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
Future<String?> getCurrentWorkerId() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    return user.uid; // El workerId es el UID del usuario autenticado
  } else {
    return null; // El usuario no está autenticado
    }
}