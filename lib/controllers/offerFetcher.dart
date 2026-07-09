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

  /// Método público que filtra los servicios por estado y usuario autenticado.
  Future<List<ServiceRequest>> fetchServicesByStatus(
    String status,
    String userId,
    String token,
    List<Offer> offers,
    String deviceId,
  ) async {
    // Se obtienen los estados válidos desde Firestore (globales o configurados)
    List<String> validStatuses = await _getValidStatusesFromFirestore();

    // Validar que el estado proporcionado sea correcto.
    if (!validStatuses.contains(status)) {
      throw ArgumentError('Estado no válido: $status');
    }

    // Se crea un ServiceRequest "dummy" para pasarlo a la función interna.
    // En este caso, el workerId del servicio se deja vacío porque el servicio puede no estar
    // asignado aún al trabajador; el filtrado se realizará a nivel de ofertas.
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
      serviceType:
          ServiceType(name: '', id: '', selectedDate: '', selectedTime: ''),
      devicesId: '',
      hasOffer: false,
      offers: [],
      subcategoryName: '',
      CreatedAt: '',
    );

    // Se invoca la función que obtiene los servicios y, para cada uno, sus ofertas filtradas.
    return await fetchOffersForUser(status, userId, token, service, deviceId);
  }

  /// Obtiene la lista de estados válidos desde la colección "offers" en Firestore.
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

  /// Método que obtiene los servicios y, para cada uno, sus ofertas filtradas por el workerId
  /// (usuario autenticado). Solo se devolverán los servicios que tengan al menos una oferta del trabajador.
  Future<List<ServiceRequest>> fetchOffersForUser(
    String type,
    String workerId, // Este es el id del trabajador autenticado
    String token,
    ServiceRequest service,
    String deviceId,
  ) async {
    try {
      // NO usar caché aquí: los servicios cambian de estado frecuentemente
      // (available → offer → in_progress) y el caché queda desactualizado.

      // Se llama a la API para obtener los servicios con el workerId.
      final response = await apiService2.getAllServices(
        token,
        "workerId",
        workerId,
        type,
      );

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> servicesData =
            List<Map<String, dynamic>>.from(json.decode(response.body));

        if (servicesData.isNotEmpty) {
          try {
            // Mapear la respuesta. Incluimos 'available' Y 'offer' porque:
            // - 'available': servicios a los que el socio puede ofertar
            // - 'offer': servicios donde ya envió una oferta (deben aparecer en "En espera")
            final List<ServiceRequest> serviceRequestsList = servicesData
                .map((item) {
                  final statusName = item['status'] as String? ?? 'offer';
                  final statusObject = Status(
                    id: statusName,
                    name: Status.getNameById(statusName),
                  );

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
                    status: statusObject,
                    isFavorite: item['isFavorite'] as bool? ?? false,
                    acceptedTerms: item['acceptedTerms'] as bool? ?? false,
                    serviceType: ServiceType(
                      name: item['serviceType'] ?? '',
                      id: '',
                      selectedDate: '',
                      selectedTime: '',
                    ),
                    devicesId: '',
                    hasOffer: false,
                    offers: [],
                    subcategoryName: item['subcategoryName'] ?? '',
                    CreatedAt: '',
                  );
                })
                .where((svc) =>
                    svc.status.id == 'available' || svc.status.id == 'offer')
                .toList();

            // Para cada servicio, obtener las ofertas del trabajador autenticado.
            List<Future> offerRequests =
                serviceRequestsList.map((serviceRequest) async {
              try {
                final offerResponses = await apiService2.getOffers(
                  "workerId",
                  workerId,
                  "offer",
                  deviceId,
                  [serviceRequest],
                  "offer",
                );

                List<Offer> filteredOffers = offerResponses
                    .map((serviceOffer) {
                      final statusName = serviceOffer.status.id;
                      final statusObject = Status(
                        id: statusName,
                        name: Status.getNameById(statusName),
                      );

                      return Offer(
                        id: serviceOffer.id,
                        workerId: serviceOffer.workerId,
                        offeredPrice: serviceOffer.offeredPrice,
                        hasOffer: serviceOffer.hasOffer,
                        serviceId: serviceRequest.id,
                        extraCosts: 0.0,
                        totalPrice: serviceOffer.offeredPrice,
                        status: statusObject,
                        userToken: '',
                        createdAt: DateTime.now(),
                        expertises: serviceOffer.expertises,
                        subcategoryName: serviceOffer.subcategoryName,
                      );
                    })
                    .where((offer) => offer.workerId == workerId)
                    .toList();

                serviceRequest.offers = filteredOffers;
              } catch (e) {
                // Si no se pueden obtener las ofertas del servicio, continuar
              }
            }).toList();

            await Future.wait(offerRequests);

            // Conservar servicios con status=='offer' (ya ofertados)
            // O servicios 'available' que tengan al menos una oferta del worker.
            final List<ServiceRequest> finalServiceRequests =
                serviceRequestsList.where((sr) {
              // Si ya tiene status 'offer', siempre mostrar
              if (sr.status.id == 'offer') return true;
              // Si es 'available' y hay oferta del worker, mostrar
              return sr.offers.isNotEmpty;
            }).toList();

            return finalServiceRequests;
          } catch (e) {
            return [];
          }
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Extrae la lista de expertises a partir del mapa recibido.
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

  /// Parsea el valor del precio ofrecido a double.
  double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}
