

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/request.dart';
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
      subcategoryName: '',
      offers: [],
      subcategory: Subcategory(id: '', name: ''),
      hasOffer: false,
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
      // Verificar caché
      final cachedRequest = await LocalCacheService.getCachedServiceRequest(userId);
      if (cachedRequest != null) {
        print('Datos del caché encontrados.');
        return [cachedRequest];
      } else {
        print('Enviando solicitud a getAllServices para el servicio ID: ${service.id}');

        final response = await apiService2.getAllServices(
          token,
          column,
          userId,
          type,
        );

        print('token=$token');
        print('column=$column');
        print('userId=$userId');
        print('type=$type');
        print('deviceId=$deviceId');

        if (response.statusCode == 200) {
          final List<Map<String, dynamic>> servicesData =
              List<Map<String, dynamic>>.from(json.decode(response.body));

          if (servicesData.isNotEmpty) {
            try {
              // Mapeamos los datos para crear una lista de ServiceRequest
              final List<ServiceRequest> serviceRequestsList =
                  servicesData.map((item) {
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
                          return MapEntry(key, (value is int) ? value.toDouble() : value);
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
                  subcategoryName: item['subcategoryName'] ?? '',
                  hasOffer: item['hasOffer'] ?? false,
                  offers: [], subcategory: Subcategory(id: '', name: ''), // Lista vacía inicialmente
                );
              }).toList();

              // Cacheamos las solicitudes de servicio
              serviceRequestsList.forEach((request) {
                LocalCacheService.cacheServiceRequest(request);
              });

              // Ahora obtenemos las ofertas de forma asincrónica
              List<Future> requests =
                  serviceRequestsList.map((serviceRequest) async {
                print('Solicitando ofertas para el servicio ID: ${serviceRequest.id}');
                try {
                  final offerResponses = await apiService2.getOffers(
                    "userId",    // Columna a filtrar
                    userId,      // Valor del usuario
                    "offer",    // Tipo de filtro
                    deviceId,
                    [serviceRequest],
                    "offer", 
                  );

                  // Mapeamos las ofertas
                  List<Offer> offers = offerResponses.map((serviceOffer) {
                    // 1. Acceder directamente a las propiedades del objeto ServiceRequest
                    final statusName = serviceOffer.status.id; // <--- Cambio clave aquí
                    final statusObject = Status(
                        id: statusName,
                        name: Status.getNameById(statusName),
                      ); // Usar el status existente
                    
                    // 2. Obtener precios desde el objeto real
                    final offeredPrice = serviceOffer.offeredPrice;

                    return Offer(
                      id: serviceOffer.id,
                      workerId: serviceOffer.workerId,
                      offeredPrice: offeredPrice,
                      hasOffer: serviceOffer.hasOffer,
                      serviceId: serviceRequest.id,
                      extraCosts: 0.0, // Si existe en ServiceRequest
                      totalPrice: serviceOffer.offeredPrice, // Ajustar según lógica real
                      status: statusObject, // Usar el status del servicio
                      userToken: '',
                      createdAt: DateTime.now(),
                      expertises: serviceOffer.expertises,
                      subcategoryName: serviceOffer.subcategoryName,
                    );
                  }).toList();

                  // Asignar las ofertas al servicio correspondiente
                  serviceRequest.offers = offers;

                  // Imprimir la cantidad de ofertas obtenidas
                  print('Ofertas obtenidas para el servicio ${serviceRequest.id}: ${offers.length}');
                } catch (e) {
                  print('Error al obtener ofertas para el servicio ${serviceRequest.id}: $e');
                }
              }).toList();

              // Esperar a que todas las solicitudes de ofertas terminen
              await Future.wait(requests);

              // Retornar la lista de solicitudes de servicio con sus ofertas
              return serviceRequestsList;
            } catch (e) {
              print('Error al procesar los datos del servicio: $e');
              return [];
            }
          } else {
            print('No se encontraron servicios disponibles.');
            return [];
          }
        } else {
          print('Error en la solicitud HTTP: ${response.statusCode}');
          return [];
        }
      }
    } catch (e) {
      print('Error en la solicitud: $e');
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
