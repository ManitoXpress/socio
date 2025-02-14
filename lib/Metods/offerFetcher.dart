

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/ServiceResponse/requestServiceType.dart';
import 'package:socio/ServiceResponse/requestStatus.dart';
import 'package:socio/Utils/cacheLocal.dart';
import 'package:socio/Utils/workerDetails.dart';
class OfferRepository {
  final ApiService2 apiService2;
  final ServiceDataFetcher serviceDataFetcher;
  final FirebaseFirestore firestore;

  OfferRepository({
    required this.apiService2,
    required this.serviceDataFetcher,
    required this.firestore,
  });

  Future<List<ServiceRequest>> fetchServicesByStatus(
    String status,
    String userId,
    String column,
    String token,
    List<Offer> offers,
    String deviceId,
  ) async {
    // Obtener la lista de estados válidos desde Firestore
    List<String> validStatuses = await _getValidStatusesFromFirestore();

    // Validar el estado proporcionado
    if (!validStatuses.contains(status)) {
      throw ArgumentError('Estado no válido: $status');
    }

    // Construir un servicio de ejemplo para pasar a fetchOffersForUser
    ServiceRequest service = ServiceRequest(
      id: '',
      serviceDateTime: DateTime.now().toString(),
      description: '',
      expertises: [],
      images: [],
      location: {},
      offeredPrice: 0.0,
      userId: userId,
      workerId: '',
      status: Status(id: status, name: Status.getNameById(status)),
      isFavorite: false,
      acceptedTerms: false,
      serviceType: ServiceType(name: '', id: '', selectedDate: '', selectedTime: ''),

      offers: [],

      hasOffer: false, devicesId: '', subcategoryName: '',
    );

    // Retornar los servicios con sus ofertas
    return await fetchOffersForUser(status, column, userId, token, service, deviceId);
  }

  Future<List<String>> _getValidStatusesFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await firestore.collection('offers').get();

      Set<String> statusSet = {};

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('status')) {
          statusSet.add(data['status'] as String);
        }
      }

      if (statusSet.isNotEmpty) {
        return statusSet.toList();
      } else {
        throw Exception('No se encontraron estados válidos en Firestore.');
      }
    } catch (e) {
      throw Exception('Error al obtener estados desde Firestore: $e');
    }
  }

  Future<List<ServiceRequest>> fetchOffersForUser(
      String type,
      String column,
      String userId,
      String token,
      ServiceRequest service,
      String deviceId,
      ) async {
    try {
      final cachedRequest = await LocalCacheService.getCachedServiceRequest(userId);
      if (cachedRequest != null) {
        return [cachedRequest];
      } else {
        final response = await apiService2.getAllServices(
          token,
          column,
          userId,
          type,
        );

        if (response.statusCode == 200) {
          final List<Map<String, dynamic>> servicesData =
          List<Map<String, dynamic>>.from(json.decode(response.body));

          if (servicesData.isNotEmpty) {
            try {
              // 1. Obtener especialidades del trabajador
              final workerExpertises = await apiService2.getWorkerExpertises();
              final expertiseNames = workerExpertises
                  .map((e) => (e['name'] as String).toLowerCase().trim())
                  .toSet();

              // 2. Mapear y filtrar servicios
              final List<ServiceRequest> serviceRequestsList = servicesData
                  .map((item) {
                final statusName = item['status'] as String? ?? 'offer';
                return ServiceRequest(
                  expertises: _extractExpertises(item),
                  id: item['id'] ?? '',
                  serviceDateTime: item['serviceDateTime'] ?? '',
                  description: item['description'] ?? '',
                  images: (item['images'] as List<dynamic>?)
                      ?.map((image) => image as String? ?? '')
                      .toList() ??
                      [],
                  location: Map<String, double>.from(
                    (item['location'] as Map<String, dynamic>?)
                        ?.map((key, value) {
                      return MapEntry(
                          key, (value is int) ? value.toDouble() : value);
                    }) ??
                        {},
                  ),
                  offeredPrice: _parseOfferedPrice(item['offeredPrice']),
                  userId: item['userId'] ?? '',
                  workerId: item['workerId'] ?? '',
                  status: Status(
                    id: statusName,
                    name: Status.getNameById(statusName),
                  ),
                  isFavorite: item['isFavorite'] as bool? ?? false,
                  acceptedTerms: item['acceptedTerms'] as bool? ?? false,
                  serviceType: ServiceType(
                    name: item['serviceType'] ?? '',
                    id: '',
                    selectedDate: '',
                    selectedTime: '',
                  ),
                  hasOffer: item['hasOffer'] ?? false,
                  offers: [],
                  devicesId: '',
                  subcategoryName: item['subcategoryName'] ?? '',
                );
              })
              // 3. Filtrar por estado y especialidad
                  .where((service) =>
              service.status.id == 'available' &&
                  expertiseNames.contains(
                      service.subcategoryName.toLowerCase().trim()))
                  .toList();

              // 4. Cachear resultados
              serviceRequestsList.forEach(LocalCacheService.cacheServiceRequest);

              // Resto del código para obtener ofertas...
              List<Future> requests = serviceRequestsList.map((serviceRequest) async {
                try {
                  final offerResponses = await apiService2.getOffers(
                    "userId",
                    userId,
                    "offer",
                    deviceId,
                    [serviceRequest],
                    "offer",
                  );

                  List<Offer> offers = offerResponses.map((serviceOffer) {
                    return Offer(
                      id: serviceOffer.id,
                      workerId: serviceOffer.workerId,
                      offeredPrice: serviceOffer.offeredPrice,
                      hasOffer: serviceOffer.hasOffer,
                      serviceId: serviceRequest.id,
                      extraCosts: 0.0,
                      totalPrice: serviceOffer.offeredPrice,
                      status: Status(
                        id: serviceOffer.status.id,
                        name: Status.getNameById(serviceOffer.status.id),
                      ),
                      userToken: '',
                      createdAt: DateTime.now(),
                      expertises: serviceOffer.expertises,
                      subcategoryName: serviceOffer.subcategoryName,
                    );
                  }).toList();

                  serviceRequest.offers = offers;
                } catch (e) {
                  print('Error obteniendo ofertas: $e');
                }
              }).toList();

              await Future.wait(requests);
              return serviceRequestsList;
            } catch (e) {
              print('Error procesando datos: $e');
              return [];
            }
          } else {
            return [];
          }
        } else {
          return [];
        }
      }
    } catch (e) {
      print('Error general: $e');
      return [];
    }
  }
  List<Expertise> _extractExpertises(Map<String, dynamic> item) {
    final expertisesArray = item['expertises'] as List<dynamic>? ?? [];
    if (expertisesArray.isNotEmpty) {
      final expertiseItem = expertisesArray.first;
      return [
        Expertise(
          id: expertiseItem['id'] ?? '',
          name: expertiseItem['name'] ?? '',
        ),
      ];
    }
    return [];
  }

  double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error al convertir el precio ofrecido a double: $e');
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}