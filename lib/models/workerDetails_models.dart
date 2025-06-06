// lib/models/worker_details_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/Utils/workerDetails.dart';

// lib/models/worker_details_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
class WorkerDetailsModel {
  final String id;
  final String displayName;
  final String email;
  final String imagePath;
  final String idDocumentImagePath;
  final int? expLevel;
  final List<Expertise> expertises;
  final String phoneNumber;

  // Campos adicionales requeridos
  final List<String> certificateImagePaths;
  final String criminalRecordImagePath;
  final String fcmToken;
  final Map<String, double> location;
  final String verificationStatus;
  final String idCardNumber;

  WorkerDetailsModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.imagePath,
    required this.idDocumentImagePath,
    required this.expLevel,
    required this.expertises,
    required this.phoneNumber,
    required this.certificateImagePaths,
    required this.criminalRecordImagePath,
    required this.fcmToken,
    required this.location,
    required this.verificationStatus,
    required this.idCardNumber,
  });

  /// Construye un WorkerDetailsModel desde un map (p. ej. desde Firestore).
  factory WorkerDetailsModel.fromMap(Map<String, dynamic> map) {
    // 1) Parseamos las expertises
    final rawExpertises = (map['expertises'] as List<dynamic>? ?? [])
        .map((e) => Expertise.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    // 2) Parseamos certificateImagePaths
    final certs = (map['certificateImagePaths'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();

    // 3) Aseguramos que location tenga lat y lng como doubles
    final locMap = map['location'] as Map<String, dynamic>? ?? {
      'lat': 0.0,
      'lng': 0.0,
    };

    // 4) Convertimos expLevel que puede venir como int o como List<dynamic>
    int? parsedExpLevel;
    final dynamic rawExp = map['expLevel'];

    if (rawExp is int) {
      // Si ya es un entero
      parsedExpLevel = rawExp;
    } else if (rawExp is String) {
      // Si viene como String (p.ej. "3")
      parsedExpLevel = int.tryParse(rawExp);
    } else if (rawExp is List<dynamic> && rawExp.isNotEmpty) {
      // Si viene como lista, tomamos el primer elemento
      final first = rawExp.first;
      if (first is int) {
        parsedExpLevel = first;
      } else if (first is String) {
        parsedExpLevel = int.tryParse(first);
      }
    } else {
      // Si viene null, o lista vacía, dejamos null
      parsedExpLevel = null;
    }

    return WorkerDetailsModel(
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      idDocumentImagePath: map['idDocumentImagePath'] as String? ?? '',
      expLevel: parsedExpLevel,
      expertises: rawExpertises,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      certificateImagePaths: certs,
      criminalRecordImagePath: map['criminalRecordImagePath'] as String? ?? '',
      fcmToken: map['fcmToken'] as String? ?? '',
      location: {
        'lat': (locMap['lat'] as num?)?.toDouble() ?? 0.0,
        'lng': (locMap['lng'] as num?)?.toDouble() ?? 0.0,
      },
      verificationStatus: map['verificationStatus'] as String? ?? '',
      idCardNumber: map['idCardNumber'] as String? ?? '',
    );
  }

  /// Construye directamente desde un DocumentSnapshot de Firestore
  factory WorkerDetailsModel.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // 1) Parseamos las expertises
    final rawExpertises = (data['expertises'] as List<dynamic>? ?? [])
        .map((e) => Expertise.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    // 2) Parseamos certificateImagePaths
    final certs = (data['certificateImagePaths'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();

    // 3) Aseguramos que location tenga lat y lng como doubles
    final locMap = data['location'] as Map<String, dynamic>? ?? {
      'lat': 0.0,
      'lng': 0.0,
    };

    // 4) Convertimos expLevel de la misma manera que en fromMap
    int? parsedExpLevel;
    final dynamic rawExp = data['expLevel'];

    if (rawExp is int) {
      parsedExpLevel = rawExp;
    } else if (rawExp is String) {
      parsedExpLevel = int.tryParse(rawExp);
    } else if (rawExp is List<dynamic> && rawExp.isNotEmpty) {
      final first = rawExp.first;
      if (first is int) {
        parsedExpLevel = first;
      } else if (first is String) {
        parsedExpLevel = int.tryParse(first);
      }
    } else {
      parsedExpLevel = null;
    }

    return WorkerDetailsModel(
      id: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      imagePath: data['imagePath'] as String? ?? '',
      idDocumentImagePath: data['idDocumentImagePath'] as String? ?? '',
      expLevel: parsedExpLevel,
      expertises: rawExpertises,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      certificateImagePaths: certs,
      criminalRecordImagePath:
          data['criminalRecordImagePath'] as String? ?? '',
      fcmToken: data['fcmToken'] as String? ?? '',
      location: {
        'lat': (locMap['lat'] as num?)?.toDouble() ?? 0.0,
        'lng': (locMap['lng'] as num?)?.toDouble() ?? 0.0,
      },
      verificationStatus: data['verificationStatus'] as String? ?? '',
      idCardNumber: data['idCardNumber'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'imagePath': imagePath,
      'idDocumentImagePath': idDocumentImagePath,
      'expLevel': expLevel,
      'expertises': expertises.map((e) => e.toMap()).toList(),
      'phoneNumber': phoneNumber,
      'certificateImagePaths': certificateImagePaths,
      'criminalRecordImagePath': criminalRecordImagePath,
      'fcmToken': fcmToken,
      'location': location,
      'verificationStatus': verificationStatus,
      'idCardNumber': idCardNumber,
    };
  }
}
