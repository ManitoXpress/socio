import 'dart:convert';

import 'package:socio/Metods/RegisController.dart';
class ServiceRequest {
  String serviceDateTime;
  String id;
  String description;
  List<String> images;
  Map<String, double> location;
  double offeredPrice;
  ServiceType serviceType;
  String userId;
  bool isFavorite;
  String? selectedDate;
  String? selectedTime;
  bool acceptedTerms;
  List<Expertises> expertises; // Cambiado a una lista de Expertises
  late Status status;
  final String subcategoryName;

  ServiceRequest({
    required this.serviceDateTime,
    required this.id,
    required this.description,
    required this.images,
    required this.location,
    required this.offeredPrice,
    required this.serviceType,
    required this.userId,
    required this.isFavorite,
    this.selectedDate,
    this.selectedTime,
    required this.acceptedTerms,
    required this.expertises, // Se espera una lista de Expertises
    required this.status,
    required this.subcategoryName,
  });

  // Método para convertir la clase en un mapa
  Map<String, dynamic> toMap() {
    return {
      'serviceDateTime': serviceDateTime,
      'id': id,
      'description': description,
      'status': status.toMap(),
      'images': images,
      'location': location,
      'offeredPrice': offeredPrice,
      'serviceType': serviceType.toMap(),
      'userId': userId,
      'isFavorite': isFavorite,
      'selectedDate': selectedDate,
      'selectedTime': selectedTime,
      'acceptedTerms': acceptedTerms,
      'expertises': expertises.map((e) => e.toMap()).toList(), // Convertir a Map
      'subcategoryName':subcategoryName,
    };
  }

  // Método para crear una instancia desde un snapshot/mapa
  factory ServiceRequest.fromSnapshot(Map<String, dynamic> map) {
    return ServiceRequest(
      serviceDateTime: map['serviceDateTime'] ?? '',
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      location: Map<String, double>.from(map['location'] ?? {}),
      offeredPrice: _parseOfferedPrice(map['offeredPrice']),
      serviceType: ServiceType.fromMap(map['serviceType'] ?? {}),
      userId: map['userId'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
      selectedDate: map['selectedDate'],
      selectedTime: map['selectedTime'],
      acceptedTerms: map['acceptedTerms'] ?? false,
      expertises: (map['expertises'] as List<dynamic>)
          .map((e) => Expertises.fromJson(e as Map<String, dynamic>))
          .toList(), // Convertir de JSON a lista de Expertises
      status: Status(
        id: map['status'] ?? '',
        name: Status.getNameById(map['status'] ?? ''),
      ),
      subcategoryName:map['subcategoryName']?? '',
    );
  }

  // Función para convertir el precio ofrecido a un número decimal
  static double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error al convertir el precio ofrecido a double: $e');
        return 0.0;
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}


class ServiceType {
  String id;
  String name;
  String selectedDate;
  String selectedTime;

  ServiceType({
    required this.id,
    required this.name,
    required this.selectedDate,
    required this.selectedTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'selectedDate': selectedDate,
      'selectedTime': selectedTime,
    };
  }

  factory ServiceType.fromMap(Map<String, dynamic> map) {
    return ServiceType(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      selectedDate: map['selectedDate'] ?? '',
      selectedTime: map['selectedTime'] ?? '',
    );
  }
}
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
  List<Expertises> expertises;
  List<String> expLevel;
  String certificateImagePaths;
  Map<String, double?>? location;
  String paymentType;
  String email;
  RegistrationData registrationData;

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
      certificateImagePaths: json['criminalRecordImagePath'] ?? '',
      idCardNumber: json['idCardNumber'] ?? '',
      location: json['location'] != null
          ? Map<String, double?>.from(json['location'])
          : null,
      idDocumentImagePath: json['idDocumentImagePath'] ?? '',
      idDocumentImagePath2: json['idDocumentImagePath2'] ?? '',
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
        email: json['email'] ?? '', imagePathList: [], criminalRecordImagePath: '', certificateImagePaths: '',
      ),
    );
  }

  static List<String> _convertToList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  static List<Expertises> _convertToExpertisesList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((item) => Expertises.fromJson(item)).toList();
    }
    return [];
  }
}



class Category {
  final String id;
  final String name;
  final List<Expertises> expertises;

  Category({required this.id, required this.name, required this.expertises});

  factory Category.fromJson(Map<String, dynamic> json) {
    List<dynamic> expertisesData = json['expertises'];
    List<Expertises> expertises =
    expertisesData.map((e) => Expertises.fromJson(e)).toList();
    return Category(
      id: json['id'],
      name: json['name'],
      expertises: expertises,
    );
  }
}

class Expertises {
  final String id;
  final String name;

  Expertises({required this.id, required this.name});

  factory Expertises.fromJson(Map<String, dynamic> json) {
    return Expertises(
      id: json['id'],
      name: json['name'],
    );
  }

  // Agregar este método para convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Status {
  final String id;
  final String name;

  Status({required this.id, required this.name});

  // Mapa inverso para buscar el nombre por ID
  static final Map<String, String> _nameById = {
    "available": "Disponible",
    "offer": "Ofertado",
    "in_progress": "En curso",
    "completed": "Completado",
    "cancelled": "Cancelado",
    // Agrega más asignaciones de ID a nombre según sea necesario
  };

  // Método estático para obtener el nombre por ID
  static String getNameById(String id) {
    return _nameById[id] ?? 'Desconocido';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Método de fábrica para crear una instancia de Status desde un mapa
  factory Status.fromMap(Map<String, dynamic> map) {
    return Status(
        id: map['id'] ?? '',
        name: getNameById(map['id'] ?? ''),
        );
    }
}