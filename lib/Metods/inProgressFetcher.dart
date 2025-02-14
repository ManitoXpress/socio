
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socio/ServiceResponse/baseurl.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/ServiceResponse/requestServiceType.dart';
import 'package:socio/ServiceResponse/requestStatus.dart';
import 'package:socio/Utils/cacheLocal.dart';
import 'package:socio/main.dart';
class ServiceRepositoryInProgress {
  final ApiService2 apiService;
  final FirebaseFirestore firestore;
  final String baseUrl = ApiConfiguration.baseUrl;

  ServiceRepositoryInProgress({required this.apiService, required this.firestore});

  Future<List<ServiceRequest>> fetchServicesByInProgress(
      String status,
      String userId,
      String column,
      String token,
      ) async {
    List<String> validStatuses = await _getValidStatusesFromFirestore();

    if (!validStatuses.contains(status)) {
      throw ArgumentError('Estado no válido: $status');
    }

    return await _fetchServicesByInProgress(status, column, userId, token);
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

  Future<List<ServiceRequest>> _fetchServicesByInProgress(
      String status,
      String column,
      String userId,
      String token,
      ) async {
    try {
      final cachedRequest = await LocalCacheService.getCachedServiceRequest(userId);
      if (cachedRequest != null && (cachedRequest.status.id == 'in_progress' || cachedRequest.status.id == 'pending_confirmation')) {
        return [cachedRequest];
      }

      final deviceId = await obtenerDeviceId();
      final response = await apiService.getAllServices(token, column, userId, status);

      if (response.statusCode != 200) {
        return [];
      }

      final List<Map<String, dynamic>> servicesData = List<Map<String, dynamic>>.from(json.decode(response.body));

      // 1. Filtrar servicios por estado
      final filteredServices = servicesData.where((item) =>
      item['status'] == 'in_progress' || item['status'] == 'pending_confirmation'
      ).toList();

      // 2. Mapear a objetos ServiceRequest
      List<ServiceRequest> serviceRequestsList = filteredServices.map((item) {
        final statusName = (item['status'] as String?) ?? 'in_progress';
        if (statusName != 'in_progress' && statusName != 'pending_confirmation') {
          return null;
        }

        return ServiceRequest(
            id: item['id']?.toString() ?? '',
        serviceDateTime: item['serviceDateTime']?.toString() ?? '',
        description: item['description']?.toString() ?? '',
        expertises: _extractExpertises(item),
        images: (item['images'] as List<dynamic>?)?.map((e) => e?.toString() ?? '').toList() ?? [],
        location: Map<String, double>.from(
        (item['location'] as Map<String, dynamic>?)?.map((key, value) =>
        MapEntry(key, (value as num).toDouble())) ?? {}
        ),
        offeredPrice: _parseOfferedPrice(item['offeredPrice']),
        userId: item['userId']?.toString() ?? '',
        workerId: '',
        status: Status(
        id: statusName,
        name: Status.getNameById(statusName),
        ), devicesId: '', serviceType: ServiceType(
        name: item['serviceType']?['name']?.toString() ?? '',
        id: item['serviceType']?['id']?.toString() ?? '',
        selectedDate: item['serviceType']?['selectedDate']?.toString() ?? '',
        selectedTime: item['serviceType']?['selectedTime']?.toString() ?? '',
        ),isFavorite: item['isFavorite'] as bool? ?? false,  acceptedTerms: item['acceptedTerms'] as bool? ?? false,
        subcategoryName: item['subcategoryName']?.toString() ?? '', hasOffer: false, offers: []);
      }).whereType<ServiceRequest>().toList();

      // 3. Obtener especialidades del trabajador
      final workerExpertises = await apiService.getWorkerExpertises();
      final expertiseNames = workerExpertises
          .map((e) => (e['name'] as String).toLowerCase().trim())
          .toSet();

      // 4. Filtrar por coincidencia de especialidad
      serviceRequestsList = serviceRequestsList.where((service) =>
          expertiseNames.contains(service.subcategoryName.toLowerCase().trim()))
          .toList();

      // 5. Obtener ofertas para cada servicio
      List<ServiceRequest> validServices = [];
      for (var service in serviceRequestsList) {
        try {
          final List<ServiceRequest> offers = await apiService.getOffers(
              'in_progress',
              deviceId,
              'pending_confirmation',
              deviceId,
              serviceRequestsList,
              status
          );

          if (offers.isNotEmpty) {
            service.workerId = offers.first.workerId;
            service.hasOffer = true;
            service.offers = offers.first.offers;
          }
          validServices.add(service);
        } catch (e) {
          print('Error obteniendo ofertas para ${service.id}: $e');
        }
      }

      // 6. Cachear y retornar resultados
      validServices.forEach(LocalCacheService.cacheServiceRequest);
      return validServices.where((s) => s.workerId.isNotEmpty).toList();
    } catch (e) {
      print('Error crítico en _fetchServicesByInProgress: ${e.toString()}');
      return [];
    }
  }

  List<Expertise> _extractExpertises(Map<String, dynamic> item) {
    final expertisesArray = item['expertises'] as List<dynamic>? ?? [];
    return expertisesArray.map((exp) => Expertise(
      id: exp['id']?.toString() ?? '',
      name: exp['name']?.toString() ?? '',
    )).toList();
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