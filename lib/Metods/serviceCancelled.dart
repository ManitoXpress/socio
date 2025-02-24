
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socio/ServiceResponse/baseurl.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/ServiceResponse/requestServiceType.dart';
import 'package:socio/ServiceResponse/requestStatus.dart';
import 'package:socio/Utils/cacheLocal.dart';
import 'package:socio/main.dart';

class ServiceRepositoryCancelled {
  final ApiService apiService;
  final FirebaseFirestore firestore;
  final String baseUrl = ApiConfiguration.baseUrl;

  ServiceRepositoryCancelled({required this.apiService, required this.firestore});

  Future<List<ServiceRequest>> fetchServicesByCancelled(
    String status,
    String userId,
    String column,
    String token,
    List<Offer> offers, // Agregado el parámetro de ofertas
  ) async {
    // Obtener la lista de estados válidos desde Firestore
    List<String> validStatuses = await _getValidStatusesFromFirestore();

    // Validar el estado proporcionado con los valores de Firestore
    if (!validStatuses.contains(status)) {
      throw ArgumentError('Estado no válido: $status');
    }

    // Llamar al método privado para realizar la lógica principal
    return await _fetchServicesByInprogress(status, column, userId, token, offers);
  }

  // Método privado para obtener los estados válidos desde Firestore
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

      if (statusSet.isNotEmpty) {
        return statusSet.toList();
      } else {
        throw Exception('No se encontraron estados válidos en Firestore.');
      }
    } catch (e) {
      throw Exception('Error al obtener estados desde Firestore: $e');
    }
  }

  // Método privado para obtener los servicios por estado (en este caso, "cancelled")
  Future<List<ServiceRequest>> _fetchServicesByInprogress(
    String type,
    String column,
    String userId,
    String token,
    List<Offer> offers,
  ) async {
    try {
      // Verificar si hay un servicio cacheado para el usuario
      final cachedRequest = await LocalCacheService.getCachedServiceRequest(userId);
      if (cachedRequest != null) {
        if (cachedRequest.status.id == 'cancelled') {
          print('Datos del caché encontrados y filtrados por cancelled...');
          return [cachedRequest];
        } else {
          print('Datos en caché no tienen estado cancelled...');
          return [];
        }
      } else {
        final deviceId = await obtenerDeviceId();

        print('Parámetro type: $type');
        print('Parámetro column: $column');
        print('Parámetro userId: $userId');
        print('Parámetro deviceId: $deviceId');

        // 1. Obtener especialidades del trabajador
        final workerExpertises = await ApiService2().getWorkerExpertises();
        final expertiseNames = workerExpertises
            .map((e) => (e['name'] as String).toLowerCase().trim())
            .toSet();

        // 2. Obtener servicios del API
        final response = await ApiService2().getAllServices(token, "status", type, "services");

        if (response.statusCode == 200) {
          final List<Map<String, dynamic>> servicesData =
              List<Map<String, dynamic>>.from(json.decode(response.body));

          if (servicesData.isNotEmpty) {
            try {
              // 3. Mapear y filtrar servicios:
              // Se mantienen solo aquellos con estado 'cancelled' y que coincidan con la especialidad del trabajador
              final List<ServiceRequest> serviceRequestsList = servicesData
                  .map((item) => _mapToServiceRequest(item))
                  .where((service) =>
                      service.status.id == 'cancelled' &&
                      expertiseNames.contains(
                          service.subcategoryName.toLowerCase().trim()))
                  .toList();

              // 4. Para cada servicio, obtener sus ofertas y filtrarlas por workerId (trabajador autenticado)
              List<ServiceRequest> validServices = [];
              for (var service in serviceRequestsList) {
                try {
                  final List<ServiceRequest> offersResponse = await ApiService2().getOffers(
                    "workerId",    // Columna por la que se filtra
                    userId,        // Valor: id del trabajador autenticado
                    "status",       // Tipo (o estado) de la oferta (ajústalo si es necesario)
                    deviceId,
                    [service],     // Se consulta para este servicio en particular
                    type,          // Se pasa el mismo estado (en este caso "cancelled")
                  );

                  // Filtrar las ofertas para conservar solo las que tengan workerId igual a userId
                  final List<ServiceRequest> filteredOffers =
                      offersResponse.where((offer) => offer.workerId == userId).toList();

                  if (filteredOffers.isNotEmpty) {
                    // Si se encontró al menos una oferta, se asigna el workerId, se marca que tiene oferta y se asignan las ofertas
                    service.workerId = filteredOffers.first.workerId;
                    service.hasOffer = true;
                    service.offers = filteredOffers.first.offers;
                    validServices.add(service);
                  }
                } catch (e) {
                  print('Error obteniendo ofertas para ${service.id}: $e');
                }
              }

              // 5. Cachear resultados y retornar los servicios válidos
              validServices.forEach(LocalCacheService.cacheServiceRequest);
              return validServices;
            } catch (e) {
              print('Error procesando servicios: $e');
              return [];
            }
          } else {
            print('No hay servicios disponibles');
            return [];
          }
        } else {
          print('Error HTTP: ${response.statusCode}');
          return [];
        }
      }
    } catch (e) {
      print('Error general: $e');
      return [];
    }
  }

  // Función auxiliar para mapear los datos del servicio a un objeto ServiceRequest
  ServiceRequest _mapToServiceRequest(Map<String, dynamic> item) {
    final statusName = item['status'] as String? ?? 'cancelled';
    final statusObject = Status(
      id: statusName,
      name: Status.getNameById(statusName),
    );

    final expertisesArray = item['expertises'] as List<dynamic>? ?? [];
    final expertiseItem = expertisesArray.isNotEmpty ? expertisesArray.first : {};

    return ServiceRequest(
      expertises: [
        Expertise(
          id: expertiseItem['id'] ?? '',
          name: expertiseItem['name'] ?? '',
        )
      ],
      id: item['id'] ?? '',
      serviceDateTime: item['serviceDateTime'] ?? '',
      description: item['description'] ?? '',
      images: (item['images'] as List<dynamic>?)
              ?.map((image) => image as String? ?? '')
              .toList() ??
          [],
      location: Map<String, double>.from(
        (item['location'] as Map<String, dynamic>?)?.map((key, value) {
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
      devicesId: '',
      hasOffer: false,
      offers: [],
      subcategoryName: item['subcategoryName'] ?? '',
    );
  }

  // Método privado para parsear el precio ofrecido a double
  double _parseOfferedPrice(dynamic value) {
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
