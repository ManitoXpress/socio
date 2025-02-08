

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socio/ServiceResponse/baseurl.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/cacheLocal.dart';
import 'package:socio/main.dart';

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;


class ServiceRepository {
  final FirebaseFirestore firestore;
  final String baseUrl = ApiConfiguration.baseUrl;
  final ApiService2 apiService;

  ServiceRepository({required this.firestore, required this.apiService,});
  

  Future<List<ServiceRequest>> fetchServicesByStatus(
    String status,
    String workerId, // Recibe directamente el ID del trabajador
    String column,
    String token,
    List<Offer> offers,
  ) async {
    List<String> validStatuses = await _getValidStatusesFromFirestore();
    if (!validStatuses.contains(status)) {
      throw ArgumentError('Estado no válido: $status');
    }
    return await _fetchServicesByStatus(status, column, workerId, token, offers);
  }

  Future<List<String>> _getValidStatusesFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await firestore.collection('services').get();
      Set<String> statusSet = {};
      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('status')) {
          statusSet.add(data['status'] as String);
        }
      }
      return statusSet.toList();
    } catch (e) {
      throw Exception('Error al obtener estados desde Firestore: $e');
    }
  }

  Future<List<ServiceRequest>> _fetchServicesByStatus(
  String type,
  String column,
  String workerId, // ID del documento en 'workers'
  String token,
  List<Offer> offers,
) async {
  try {
    // Llamada a la API para obtener servicios ya filtrados
    final response = await ApiService2().getAllServices(token, "userId", column, type);

    if (response.statusCode == 200) {
      final List<Map<String, dynamic>> servicesData =
          List<Map<String, dynamic>>.from(json.decode(response.body));

      print('Datos de los servicios desde la API: $servicesData');

      final List<ServiceRequest> serviceRequestsList = servicesData.map((item) {
        final statusName = item['status'] as String? ?? 'available';
        final statusObject = Status(
          id: statusName,
          name: Status.getNameById(statusName),
        );

        final Map<String, dynamic>? subcategoryData =
            item['subcategory'] as Map<String, dynamic>?;
        final String subcategoryId = subcategoryData?['id']?.toString() ?? '';
        final String subcategoryName = subcategoryData?['name']?.toString() ?? '';

        return ServiceRequest(
          expertises: [],
          id: item['id']?.toString() ?? '',
          serviceDateTime: item['serviceDateTime']?.toString() ?? '',
          description: item['description']?.toString() ?? '',
          images: (item['images'] as List<dynamic>?)
                  ?.map((image) => image.toString())
                  .toList() ??
              [],
          location: Map<String, double>.from(
            (item['location'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(key, (value is int) ? value.toDouble() : value),
                ) ??
                {},
          ),
          offeredPrice: _parseOfferedPrice(item['offeredPrice']),
          userId: item['userId']?.toString() ?? '',
          workerId: item['workerId']?.toString() ?? '',
          status: statusObject,
          isFavorite: item['isFavorite'] as bool? ?? false,
          acceptedTerms: item['acceptedTerms'] as bool? ?? false,
          serviceType: ServiceType(
            name: item['serviceType']?.toString() ?? '',
            id: '',
            selectedDate: '',
            selectedTime: '',
          ),
          subcategoryName: subcategoryName,
          hasOffer: false,
          offers: [],
          subcategory: Subcategory(id: subcategoryId, name: subcategoryName),
        );
      }).toList();

      print('Servicios obtenidos: ${serviceRequestsList.length}');
      return serviceRequestsList;
    } else {
      throw Exception('Error HTTP ${response.statusCode}');
    }
  } catch (e) {
    print('Error crítico: $e');
    return [];
  }
}


  Future<List<String>> _getWorkerExpertises(String userId, String token) async {
    try {
      print('[Repository] Solicitando expertises para worker: $userId');
      final expertises = await apiService.getWorkerExpertises();
      print('[Repository] Expertises recibidas: ${expertises.length}');
      return expertises;
    } catch (e) {
      print('[Repository] Error al obtener expertises: $e');
      return [];
    }
  }

  bool _filterService(ServiceRequest service, List<String> expertises) {
    final subcategoryId = service.subcategory.id.trim(); // Elimina espacios
    final isAvailable = service.status.id == 'available';
    final matches = expertises.any((id) => id.trim() == subcategoryId); // Comparación exacta
    
    print(
      'Filtro: ${service.id} | '
      'Subcategoría: $subcategoryId | '
      'Disponible: $isAvailable | '
      'Match: $matches | '
      'Expertises: $expertises' // Debug 5
    );
    
    return isAvailable && matches;
  }

  double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error al convertir precio: $e');
        return 0.0;
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}