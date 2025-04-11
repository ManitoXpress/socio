
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:socio/ServiceResponse/baseurl.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/ServiceResponse/requestServiceType.dart';
import 'package:socio/ServiceResponse/requestStatus.dart';
import 'package:socio/Utils/cacheLocal.dart';
import 'package:socio/main.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socio/main.dart';
import 'package:http/http.dart' as http;

class ServiceRepository {
  final ApiService apiService;
  final FirebaseFirestore firestore;
  final String baseUrl = ApiConfiguration.baseUrl;

  ServiceRepository({required this.apiService, required this.firestore});

  /// Obtiene el workerId del usuario autenticado
  String? getAuthenticatedWorkerId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // Función pública que permite filtrar servicios por estado desde Firestore
  Future<List<ServiceRequest>> fetchServicesByStatus(
    String status,
    String userId, // Nota: este parámetro debería ser reemplazado o interpretado según tu lógica
    String column,
    String token,
    List<Offer> offers, // Agregado el parámetro de ofertas
  ) async {
    // Obtener el workerId autenticado
    final workerId = getAuthenticatedWorkerId();
    if (workerId == null || workerId.isEmpty) {
      print('Error: No se encontró un usuario autenticado.');
      throw Exception('Usuario no autenticado');
    }
    print('Usuario autenticado, workerId: $workerId');

    // Obtener la lista de estados válidos desde Firestore
    List<String> validStatuses = await _getValidStatusesFromFirestore();

    // Validar el estado proporcionado con los valores de Firestore
    if (!validStatuses.contains(status)) {
      throw ArgumentError('Estado no válido: $status');
    }

    // Llamar al método privado para realizar la lógica principal usando el workerId autenticado
    return await _fetchServicesByStatus(status, column, workerId, token, offers);
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

  // Método privado para obtener los servicios por estado
  Future<List<ServiceRequest>> _fetchServicesByStatus(
    String type,
    String column,
    String workerId, // Se asume que es el workerId autenticado
    String token,
    List<Offer> offers,
  ) async {
    try {
      final cachedRequest = await LocalCacheService.getCachedServiceRequest(workerId);
      if (cachedRequest != null) {
        if (cachedRequest.status.id == 'available') {
          print('Datos del caché encontrados y filtrados por available...');
          return [cachedRequest];
        } else {
          print('Datos en caché no tienen estado available...');
          return [];
        }
      } else {
        final deviceId = await obtenerDeviceId();

        print('Parámetro type: $type');
        print('Parámetro column: $column');
        print('Parámetro workerId: $workerId');
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
              // 3. Filtrar servicios
              // 3. Filtrar servicios
              final List<ServiceRequest> serviceRequestsList = servicesData
                  .map((item) => _mapToServiceRequest(item))
                  .where((service) {
                    // Se recorre la lista de ofertas, proveniente de la colección 'offer'
                    // Para cada oferta, se compara que el id del servicio coincida y que el workerId
                    // de la oferta sea el del trabajador autenticado.
                    final existeOfertaDelWorker = offers.any((offer) {
                      final coincide = offer.serviceId == service.id && offer.workerId == workerId;
                      if (coincide) {
                        print('Oferta encontrada para el servicio ${service.id}: '
                            'offer.workerId = ${offer.workerId}, workerId esperado = $workerId');
                      } else {
                        if (offer.serviceId == service.id) {
                          print('Oferta encontrada para el servicio ${service.id} pero con otro workerId: '
                              'offer.workerId = ${offer.workerId}, workerId esperado = $workerId');
                        }
                      }
                      return coincide;
                    });

                    if (existeOfertaDelWorker) {
                      print('Se descarta el servicio ${service.id} porque ya existe una oferta del worker $workerId');
                    } else {
                      print('Se mantiene el servicio ${service.id} ya que no tiene oferta del worker $workerId');
                    }
                    
                    // Se retorna el servicio sólo si está 'available', la especialidad coincide y no hay oferta del worker.
                    return service.status.id == 'available' &&
                        expertiseNames.contains(service.subcategoryName.toLowerCase().trim()) &&
                        !existeOfertaDelWorker;
                  })
                  .toList();


              print('Servicios filtrados: ${serviceRequestsList.length}');
              // Cachear resultados
              serviceRequestsList.forEach(LocalCacheService.cacheServiceRequest);

              return serviceRequestsList;
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

  // Función auxiliar para mapear los datos del servicio
  ServiceRequest _mapToServiceRequest(Map<String, dynamic> item) {
    final statusName = item['status'] as String? ?? 'available';
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

  // Método privado para parsear el precio ofrecido
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
