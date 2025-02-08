import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socio/Metods/RegisController.dart';
class Offer {
  final String id;
  final String serviceId;
  final String workerId;
  final double offeredPrice;
  final double extraCosts;
  final double totalPrice;
  late Status status;
  final bool hasOffer;
  final String userToken;
  final DateTime createdAt;
  List<Expertise> expertises;
  final String subcategoryName;
  WorkerDetails? workerDetails;
  
  

  Offer({
    required this.id,
    required this.serviceId,
    required this.workerId,
    required this.offeredPrice,
    required this.extraCosts,
    required this.totalPrice,
    required this.status,
    required this.hasOffer,
    required this.userToken,
    required this.createdAt,
    required this.expertises,
    required this.subcategoryName,
    this.workerDetails,
  });

  // Método toMap para convertir la oferta a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceId': serviceId,
      'workerId': workerId,
      'offeredPrice': offeredPrice,
      'extraCosts': extraCosts,
      'totalPrice': totalPrice,
      'status': status.toMap(),
      'hasOffer': hasOffer,
      'userToken': userToken,
      'createdAt': createdAt.toIso8601String(),  // Usar toIso8601String para formato de fecha
      'expertises': expertises.map((e) => e.toMap()).toList(),
      'subcategoryName': subcategoryName,
      'workerDetails': workerDetails?.toMap(),
    };
  }

  // Método de fábrica para crear una oferta a partir de un mapa
  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      id: map['id'] ?? '',
      serviceId: map['serviceId'] ?? '',
      workerId: map['workerId'] ?? '',
      offeredPrice: map['offeredPrice']?.toDouble() ?? 0.0,
      extraCosts: map['extraCosts']?.toDouble() ?? 0.0,
      totalPrice: map['totalPrice']?.toDouble() ?? 0.0,
      status: Status(
        id: map['status'] ?? '',
        name: Status.getNameById(map['status'] ?? ''),
      ),
      hasOffer: map['hasOffer'] ?? false,
      userToken: map['userToken'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toString()),
      expertises: map['expertises'] != null
          ? List<Expertise>.from(
              (map['expertises'] as List).map((e) => Expertise.fromMap(e)))
          : [],
      subcategoryName: map['subcategoryName'] ?? '',
      workerDetails: map['workerDetails'] != null
          ? WorkerDetails.fromMap(map['workerDetails'])
          : null,
      
      
      
    );
  }
}
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
  List<Expertise> expertises; // Cambiado a una lista de Expertises
  late Status status;
  List<Offer>
      offers;
  final String subcategoryName;
  WorkerDetails? workerDetails;
  String workerId;
  final Subcategory subcategory;
  late final bool hasOffer;

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
    required this.offers,
    required this.workerId,
    required this.subcategory,
    required this.hasOffer,
  
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
      'offers': offers.map((offer) => offer.toMap()).toList(),
      'workerId':workerId,

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
      workerId: map['workerId']?? '',
      isFavorite: map['isFavorite'] ?? false,
      selectedDate: map['selectedDate'],
      selectedTime: map['selectedTime'],
      acceptedTerms: map['acceptedTerms'] ?? false,
      expertises: map['expertises'] != null
          ? List<Expertise>.from(
              (map['expertises'] as List).map((e) => Expertise.fromMap(e)))
          : [], // Convertir de JSON a lista de Expertises
      status: Status(
        id: map['status'] ?? '',
        name: Status.getNameById(map['status'] ?? ''),
      ),
      subcategoryName:map['subcategoryName']?? '',
      offers: map['offers'] != null
          ? List<Offer>.from(
              (map['offers'] as List).map((e) => Offer.fromMap(e)))
          : [],
      subcategory: Subcategory.fromMap(map['subcategory'] ?? {}),
      hasOffer: map['hasOffer'] ?? false,
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

class WorkerDetails {
  final String id;
  final List<String> certificateImagePaths;
  final String idDocumentImagePath;
  final String imagePath;
  final String phoneNumber;
  final String displayName;
  final String email;
  final List<String> expLevel;
  final List<Expertise> expertises;
  final String criminalRecordImagePath;
  final String fcmToken;
  final Location location; // Cambiado a un objeto Location
  final String verificationStatus;
  final String idCardNumber;

  WorkerDetails({
    required this.id,
    required this.certificateImagePaths,
    required this.idDocumentImagePath,
    required this.imagePath,
    required this.phoneNumber,
    required this.displayName,
    required this.email,
    required this.expLevel,
    required this.expertises,
    required this.criminalRecordImagePath,
    required this.fcmToken,
    required this.location,
    required this.verificationStatus,
    required this.idCardNumber,
  });

  // Constructor fromMap
  factory WorkerDetails.fromMap(Map<String, dynamic> map) {
    return WorkerDetails(
      id: map['id'] ?? '',
      certificateImagePaths: List<String>.from(map['certificateImagePaths'] ?? []),
      idDocumentImagePath: map['idDocumentImagePath'] ?? '',
      imagePath: map['imagePath'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      expLevel: List<String>.from(map['expLevel'] ?? []),
      expertises: (map['expertises'] as List<dynamic>?)
              ?.map((item) => Expertise.fromMap(item))
              .toList() ??
          [],
      criminalRecordImagePath: map['criminalRecordImagePath'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      location: map['location'] != null
          ? Location.fromMap(map['location']) // Mapeo del objeto Location
          : Location(lat: 0.0, lng: 0.0), // Valor por defecto
      verificationStatus: map['verificationStatus'] ?? '',
      idCardNumber: map['idCardNumber'] ?? '',
    );
  }

  // Método toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'certificateImagePaths': certificateImagePaths,
      'idDocumentImagePath': idDocumentImagePath,
      'imagePath': imagePath,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'email': email,
      'expLevel': expLevel,
      'expertises': expertises.map((e) => e.toMap()).toList(),
      'criminalRecordImagePath': criminalRecordImagePath,
      'fcmToken': fcmToken,
      'location': location.toMap(), // Convertir objeto Location a mapa
      'verificationStatus': verificationStatus,
      'idCardNumber': idCardNumber,
    };
  }
}

// Clase Location
class Location {
  final double lat;
  final double lng;

  Location({
    required this.lat,
    required this.lng,
  });

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

// Clase Expertise
class Expertise {
  final String name;
  final String id;

  Expertise({
    required this.name,
    required this.id,
  });

  factory Expertise.fromMap(Map<String, dynamic> map) {
    return Expertise(
      name: map['name'] ?? '',
      id: map['id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'id': id,
    };
  }
}



class category {
  final String id;
  final String name;

  category({required this.id, required this.name});
  factory category.fromMap(Map<String, dynamic> data) {
    return category(id: data['id'], name: data['name']);
  }
}

class Subcategory {
  final String id;
  final String name;

  Subcategory({
    required this.id,
    required this.name,
  });

  factory Subcategory.fromMap(Map<String, dynamic> map) {
    return Subcategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
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
  List<Expertise> expertises;
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

  static List<Expertise> _convertToExpertisesList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((item) => Expertise.fromMap(item)).toList();
    }
    return [];
  }
}



class Category {
  final String id;
  final String name;
  final List<Expertise> expertises;

  Category({required this.id, required this.name, required this.expertises});

  factory Category.fromJson(Map<String, dynamic> json) {
    List<dynamic> expertisesData = json['expertises'];
    List<Expertise> expertises =
    expertisesData.map((e) => Expertise.fromMap(e)).toList();
    return Category(
      id: json['id'],
      name: json['name'],
      expertises: expertises,
    );
  }
}