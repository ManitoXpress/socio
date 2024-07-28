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
  String expertises;
  late Status status;

  bool isServiceNameEmpty() {
    return (description == null || description.isEmpty);
  }

  bool isServiceTypeEmpty() {
    return (serviceType == null);
  }

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
    required this.expertises,
    required this.status,
  });

  ServiceRequest copyWith({
    String? dateTime,
    String? id,
    String? description,
    List<String>? images,
    Map<String, double>? location,
    double? offeredPrice,
    ServiceType? serviceType,
    Status? status,
    String? userId,
    bool? isFavorite,
    String? selectedDate,
    String? selectedTime,
    bool? acceptedTerms,
    String? expertises,
  }) {
    return ServiceRequest(
      serviceDateTime: dateTime ?? this.serviceDateTime,
      id: id ?? this.id,
      description: description ?? this.description,
      images: images ?? this.images,
      location: location ?? this.location,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      isFavorite: isFavorite ?? this.isFavorite,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      expertises: expertises ?? this.expertises,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceDateTime': serviceDateTime,
      'id': id,
      'description': description,
      'status': status.toMap(), // Utiliza toMap en lugar de toJson
      'images': images,
      'location': location,
      'offeredPrice': offeredPrice,
      'serviceType': serviceType.toMap(),
      'userId': userId,
      'isFavorite': isFavorite,
      'selectedDate': selectedDate,
      'selectedTime': selectedTime,
      'acceptedTerms': acceptedTerms,
      'expertises': expertises,
    };
  }

  factory ServiceRequest.fromSnapshot(Map<String, dynamic> map) {
    return ServiceRequest(
      serviceDateTime: map['dateTime'] ?? '',
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      location: Map<String, double>.from(map['location'] ?? {}),
      offeredPrice: _parseOfferedPrice(
          map['offeredPrice']), // Utiliza la función _parseOfferedPrice
      serviceType: ServiceType.fromMap(map['serviceType'] ?? {}),
      userId: map['userId'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
      selectedDate: map['selectedDate'],
      selectedTime: map['selectedTime'],
      acceptedTerms: map['acceptedTerms'] ?? false,
      expertises: map['expertises'] ?? '',
      status: Status(
        id: map['status'] ?? '',
        name: Status.getNameById(map['status'] ?? ''),
      ),
    );
  }

  // Función para convertir el precio ofrecido a un número decimal
  static double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error al convertir el precio ofrecido a double: $e');
        return 0.0; // Devuelve un valor predeterminado en caso de error
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0; // Devuelve un valor predeterminado si el valor no es String ni num
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
  List<Expertises> expertises; // Cambiado a lista de Expertises
  List<String> expLevel;
  List<String> certificateImagePaths;
  Map<String, double?>? location;
  String paymentType;
  String email;
  RegistrationData registrationData; // Nueva propiedad

  UserData({
    required this.userId,
    required this.displayName,
    required this.idCardNumber,
    required this.phoneNumber,
    required this.expertises, // Cambiado a lista de Expertises
    required this.expLevel,
    required this.imagePath,
    required this.pdfPathController,
    required this.getToken,
    required this.criminalRecordImagePath,
    required this.selectedCountryCode,
    required this.certificateImagePaths,
    required this.idDocumentImagePath,
    required this.idDocumentImagePath2,
    required this.location,
    required this.paymentType,
    required this.email,
    required this.registrationData, // Nueva propiedad
  });

  UserData.fromForm({
    required String userId,
    required String displayName,
    required String idCardNumber,
    required String phoneNumber,
    required String pdfPath,
    required String getToken,
    required List<Expertises> expertises, // Cambiado a lista de Expertises
    required List<String> expLevel,
    required String imagePath,
    required String selectedCountryCode,
    required String pdfPathController,
    required String criminalRecordImagePath,
    required List<String> certificateImagePaths,
    required String idDocumentImagePath,
    required String idDocumentImagePath2,
    required Map<String, double?>? location,
    required String paymentType,
    required String email,
  }) : this(
          userId: userId,
          displayName: displayName,
          idCardNumber: idCardNumber,
          phoneNumber: phoneNumber,
          expertises: expertises, // Cambiado a lista de Expertises
          expLevel: expLevel,
          imagePath: imagePath,
          getToken: getToken,
          pdfPathController: pdfPathController,
          criminalRecordImagePath: criminalRecordImagePath,
          selectedCountryCode: selectedCountryCode,
          certificateImagePaths: certificateImagePaths,
          idDocumentImagePath: idDocumentImagePath,
          idDocumentImagePath2: idDocumentImagePath2,
          location: location,
          paymentType: paymentType,
          email: email,
          registrationData: RegistrationData(
            userId: userId,
            displayName: displayName,
            idCardNumber: idCardNumber,
            phoneNumber: phoneNumber,
            paymentType: paymentType,
            expertises: expertises, // Cambiado a lista de Expertises
            selectedCountryCode: selectedCountryCode,
            expLevel: expLevel,
            imagePath: imagePath,
            location: location,
            idDocumentImagePath: idDocumentImagePath,
            idDocumentImagePath2: idDocumentImagePath2,
            email: email,
            imagePathList: [], criminalRecordImagePath: '',
            certificateImagePaths: [],
          ),
        );

  void setImages(String imagePath) {
    this.imagePath = imagePath;
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('email')) {
      String paymentType =
          json['paymentType'] is String ? json['paymentType'] : '';

      return UserData(
        userId: json['id'] ?? '',
        displayName: json['displayName'] ?? '',
        email: json['email'] ?? '',
        phoneNumber: json['phoneNumber'] ?? '',
        imagePath: json['imagePath'] ?? '',
        getToken: json['getToken'] ?? '',
        pdfPathController: json['pdfPathController'] ?? '',
        criminalRecordImagePath: json['criminalRecordImagePath'] ?? '',
        paymentType: paymentType,
        selectedCountryCode: json['selectedCountryCode'] ?? '',
        expertises: _convertToExpertisesList(
            json['expertises']), // Convertir a lista de Expertises
        expLevel: _convertToList(json['expLevel']),
        certificateImagePaths: _convertToList(json['certificateImagePaths']),

        idCardNumber: json['idCardNumber'] ?? '',
        location: json['location'] != null
            ? Map<String, double?>.from(json['location'])
            : null,
        idDocumentImagePath: json['idDocumentImagePath'] ?? '',
        idDocumentImagePath2: json['idDocumentImagePath2'] ?? '',
        registrationData: RegistrationData.fromForm(
          userId: json['id'] ?? '',
          displayName: json['displayName'] ?? '',
          idCardNumber: json['idCardNumber'] ?? '',
          phoneNumber: json['phoneNumber'] ?? '',
          paymentType: paymentType,
          selectedCountryCode: json['selectedCountryCode'] ?? '',
          expertises: _convertToExpertisesList(
              json['expertises']), // Convertir a lista de Expertises
          expLevel: _convertToList(json['expLevel']),
          imagePath: json['imagePath'] ?? '', // Corregido para manejar null
          location: json['location'] != null
              ? Map<String, double?>.from(json['location'])
              : null,
          idDocumentImagePath: json['idDocumentImagePath'] ?? '',
          idDocumentImagePath2: json['idDocumentImagePath2'] ?? '',
          criminalRecordImagePath: json['criminalRecordImagePath'] ?? '',
          certificateImagePaths: _convertToList(json['certificateImagePaths']),

          email: json['email'] ?? '',
          imagePathList: [],
        ),
      );
    } else {
      return UserData(
        userId: '',
        displayName: '',
        email: '',
        idCardNumber: '',
        phoneNumber: '',
        expertises: [],
        expLevel: [],
        imagePath: '',
        idDocumentImagePath: '',
        selectedCountryCode: '',
        pdfPathController: '',
        criminalRecordImagePath: '',
        location: {},
        paymentType: '',
        registrationData: RegistrationData(
          userId: '',
          displayName: '',
          idCardNumber: '',
          selectedCountryCode: '',
          phoneNumber: '',
          paymentType: '',
          expertises: [],
          imagePath: '',
          location: {},
          idDocumentImagePath: '',
          email: '',
          imagePathList: [],
          idDocumentImagePath2: '',
          criminalRecordImagePath: '',
          certificateImagePaths: [],
          expLevel: [],
        ),
        idDocumentImagePath2: '',
        certificateImagePaths: [],
        getToken: '', // O inicializa con valores predeterminados
      );
    }
  }

  static List<String> _convertToList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((dynamic item) => item.toString()).toList();
    } else if (value is String) {
      return [value];
    } else {
      return [];
    }
  }

  static List<Expertises> _convertToExpertisesList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((dynamic item) => Expertises.fromJson(item)).toList();
    } else {
      return [];
    }
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
}

class Status {
  final String id;
  final String name;

  Status({required this.id, required this.name});

  // Mapa inverso para buscar el nombre por ID
  static final Map<String, String> _nameById = {
    "available": "Disponible",
    "assigned": "Asignado",
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
}
