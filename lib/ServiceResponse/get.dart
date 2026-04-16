import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:socio/ServiceResponse/baseurl.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestCategory.dart';
import 'package:socio/ServiceResponse/requestServiceType.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/authUtils.dart';

class ApiService2 {
  final String baseUrl = ApiConfiguration.baseUrl;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>> fetchSingleService(
      String workerColumn,
      String workerValue,
      String type,
      String deviceId,
      String serviceId,
      ) async {
    // Llamas a tu método que ya funciona
    final resp = await getAllServices(
      await AuthUtils.getToken() ?? '',
      workerColumn,
      workerValue,
      type,
    );

    if (resp.statusCode != 200) {
      throw Exception('Error al obtener servicios: ${resp.statusCode}');
    }

    // Parseas el body como una lista de JSON
    final List<dynamic> data = json.decode(resp.body);
    // Buscamos el que tenga el id que queremos
    final found = data.cast<Map<String, dynamic>>().firstWhere(
          (srv) => srv['id'] == serviceId,
      orElse: () => throw Exception('Servicio no encontrado'),
    );

    return found;
  }

  Future<void> patchServiceComments(
      String serviceId,
      List<Map<String, String>> commentsList,
      ) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    if (token == null) {
      throw Exception('Token de autenticación no disponible');
    }
    final resp = await http.patch(
      Uri.parse('$baseUrl/services/$serviceId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'comments': commentsList}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error al actualizar comentarios: '
          '${resp.statusCode} ${resp.body}');
    }
  }
  // 1) GET /offers?serviceId={id}
  Future<Map<String, dynamic>> getOfferByServiceId(String serviceId) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    if (token == null) {
      throw Exception('Token de autenticación no disponible');
    }
    final url = Uri.parse('$baseUrl/offers/$serviceId');
    final resp = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (resp.statusCode == 404) {
      throw Exception('Oferta no encontrada para serviceId $serviceId');
    }
    if (resp.statusCode != 200) {
      throw Exception('Error al cargar oferta: ${resp.statusCode}');
    }
    // Suponemos que el backend responde un JSON array de ofertas
    final List data = json.decode(resp.body) as List;
    if (data.isEmpty) {
      throw Exception('No hay oferta para serviceId $serviceId');
    }
    return Map<String, dynamic>.from(data.first);
  }

  // 2) PATCH /offers/{offerId}
  Future<void> patchOffer(String offerId, Map<String, dynamic> body) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    if (token == null) {
      throw Exception('Token de autenticación no disponible');
    }
    final url = Uri.parse('$baseUrl/offers/$offerId');
    final resp = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error al actualizar oferta via HTTP: ${resp.statusCode}');
    }
    // ————— Ahora parcheamos en Firestore —————
    try {
      final docRef = FirebaseFirestore.instance
          .collection('offers').doc(offerId);
      await docRef.update(body);
    } catch (e) {
      // Dependiendo de tu lógica, podrías tirar aquí o solo notificar:
      // throw;
    }
  }



  // 3) PATCH /services/{serviceId}
  Future<void> patchService(String serviceId, Map<String, dynamic> body) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    if (token == null) {
      throw Exception('Token de autenticación no disponible');
    }
    final url = Uri.parse('$baseUrl/services/$serviceId');
    final resp = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error al actualizar servicio: ${resp.statusCode}');
    }
  }

  Future<void> updateWorkerPoints(String workerId, String token) async {
    final url = Uri.parse('$baseUrl/workers/$workerId');
    try {
      // Primero debemos obtener los valores actuales del trabajador en Firestore
      final workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .get();

      if (!workerDoc.exists) {
        return;
      }

      final workerData = workerDoc.data() as Map<String, dynamic>;
      final currentPoints = workerData['points'] ?? 0;
      final currentReferrals = workerData['successfulReferrals'] ?? 0;

      // Enviar los valores actuales al backend
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'successfulReferrals': currentReferrals,
          'points': currentPoints,
        }),
      );

      if (response.statusCode == 200) {
      } else {
      }
    } catch (e) {
    }
  }

  /// 1) Obtener el servicio completo (incluye array `comments`)
  Future<Map<String, dynamic>> getService(String serviceId) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    if (token == null) {
      throw Exception('Token de autenticación no disponible');
    }

    final url = Uri.parse('$baseUrl/services/$serviceId');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception('Error cargando servicio: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getOffers2(String offerId) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    if (token == null) {
      throw Exception('Token de autenticación no disponible');
    }
    final url = Uri.parse('$baseUrl/offers/$offerId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map)).toList();
    } else {
      throw Exception('Error cargando oferta $offerId: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getWorkerExpertises() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      final String? token = await user.getIdToken(true);
      final String userId = user.uid;

      final response = await http.get(
        Uri.parse('$baseUrl/workers/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> rawExpertises = data['expertises'] ?? [];

        final expertises = rawExpertises.map((e) {
          if (e is Map<String, dynamic>) {
            return e;
          } else {
            return {'name': e, 'id': ''};
          }
        }).toList();

        return expertises;
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ServiceResponse>> fetchServicesFromBackend(String token) async {
    try {
      final String? authToken = await AuthUtils.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        if (responseData != null) {
          final List<ServiceResponse> services = responseData
              .map((data) => ServiceResponse.fromJson(data))
              .toList();
          return services;
        } else {
          throw Exception('La respuesta del backend está vacía.');
        }
      } else {
        throw Exception('Error al cargar los servicios desde el backend');
      }
    } catch (e) {
      throw Exception('Error al cargar los servicios desde el backend');
    }
  }

  Future<http.Response> getAllServices(
      String authToken, String column, String value, String type) async {
    try {
      final String? authTokenValue = await AuthUtils.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/services?columns=$column&values=$value&type=$type'),
        headers: <String, String>{
          'Authorization': 'Bearer $authTokenValue',
        },
      );

      if (response.statusCode == 200) {
      } else {
      }
      return response;
    } catch (e) {
      throw Exception('Error al obtener datos del backend');
    }
  }

  Future<http.Response> fetchServicebyExpertises(
      String userId, String authToken, List<String> expertises) async {
    try {
      final String? authTokenValue = authToken;
      final Uri url = Uri.parse(
          '$baseUrl/services/byExpertises?userId=$userId&expertises=${expertises.join(',')}');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $authTokenValue',
        },
      );

      if (response.statusCode == 200) {
      } else {
      }
      return response;
    } catch (e) {
      throw Exception('Error al obtener datos del backend');
    }
  }

  Future<List<ServiceRequest>> getOffers(
      String column,
      String value,
      String type,
      String deviceId,
      List<ServiceRequest> services,
      String status, // Nuevo parámetro para filtrar por estado
      ) async {
    try {
      final String? authTokenValue = await AuthUtils.getToken();

      if (authTokenValue == null) {
        throw Exception('Token de autorización no encontrado');
      }

      if (services.isEmpty || services.any((service) => service.id.isEmpty)) {
        throw Exception('ID del servicio no encontrado');
      }

      List<ServiceRequest> allOffers = [];

      List<Future> requests = services.map((service) async {
        final url = Uri.parse(
          '$baseUrl/offers/${service.id}?'
              'columns=$column&'
              'values=$value&'
              'type=$type&'
              'deviceId=$deviceId&'
              'status=$status', // Añadir parámetro de estado
        );

        final response = await http.get(
          url,
          headers: <String, String>{
            'Authorization': 'Bearer $authTokenValue',
          },
        );

        if (response.statusCode == 200) {
          List<dynamic> offersJson = json.decode(response.body);
          allOffers.addAll(offersJson
              .map((offer) => ServiceRequest.fromSnapshot(offer))
              .where((offer) =>
          offer.status.id == status) // Filtro adicional en cliente
              .toList());
        } else {
          print(
              'Error al obtener ofertas para el servicio ${service.id}: ${response.statusCode}');
        }
      }).toList();

      await Future.wait(requests);
      return allOffers;
    } catch (e) {
      throw Exception('Error al obtener ofertas');
    }
  }

  Future<List<ServiceRequest>> fetchServicesBySubcategory(
      String userId, String authToken, List<String> expertiseIds) async {
    try {
      // Construimos la URL incluyendo los IDs de las especialidades
      final Uri url = Uri.parse(
          '$baseUrl/services/bySubcategories?userId=$userId&subcategoryIds=${expertiseIds.join(",")}');

      // Realizamos la solicitud GET al backend
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        // Parseamos los datos recibidos
        final data = jsonDecode(response.body) as List;
        return data.map((json) => ServiceRequest.fromSnapshot(json)).toList();
      } else {
        throw Exception(
            'Error al obtener servicios por subcategorías: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al realizar la solicitud: $e');
    }
  }

  Future<UserData> fetchUserData(String userId, String token) async {
    try {
      // Construir el header con el token
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/workers/$userId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          return UserData.fromJson(responseData);
        } else {
          throw Exception('El formato de la respuesta no es válido');
        }
      } else {
        throw Exception('Solicitud HTTP fallida: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener datos del backend');
    }
  }

  Future<UserData> fetchUserDataRef(String userId, String token) async {
    try {
      // Construir el header con el token
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/workers?userId=$userId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          return UserData.fromJson(responseData);
        } else {
          throw Exception('El formato de la respuesta no es válido');
        }
      } else {
        throw Exception('Solicitud HTTP fallida: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener datos del backend');
    }
  }

  Future<List<Category>> fetchExpertises() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken(true);

      if (token == null) {
        throw Exception('Token de autenticación no disponible');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/categories/expertises'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        final List<dynamic> data = decoded is List
            ? decoded
            : decoded['categories'] ?? [];

        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load expertises');
      }
    } catch (e) {
    rethrow;
    }
  }

  Future<http.Response> fetchServiceByExpertises(
      String userId, List<String> expertises) async {
    try {
      final String? authToken = await AuthUtils.getToken();
      final Uri url = Uri.parse(
          '$baseUrl/services/byExpertises?userId=$userId&expertises=${expertises.join(',')}');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
      } else {
        _logError(response);
      }
      return response;
    } catch (e) {
      throw Exception('Error al obtener datos del backend');
    }
  }

  Future<String?> fetchProfileImage(String userId) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        // Manejar el caso en el que el usuario no está autenticado
        return null;
      }

      final FirebaseStorage storage = FirebaseStorage.instance;

      // Ruta de la carpeta del usuario
      String userFolderPath = '${user.uid}/';

      // Obtener la referencia de la carpeta del usuario
      Reference userFolderRef = storage.ref().child(userFolderPath);

      // Listar los elementos en la carpeta del usuario
      ListResult result = await userFolderRef.listAll();

      // Filtrar solo las imágenes que tienen el prefijo "profileImage_"
      List<Reference> profileImages = result.items
          .where((item) => item.name.startsWith('profileImage_'))
          .toList();

      if (profileImages.isNotEmpty) {
        // Obtener la referencia de la primera imagen en la carpeta
        Reference firstImageRef = profileImages.first;

        // Obtener la URL de descarga de la primera imagen
        final imageUrl = await firstImageRef.getDownloadURL();
        return imageUrl;
      } else {
        print(
            'No se encontraron imágenes de perfil en la carpeta del usuario.');
        return null;
      }
    } catch (e) {
      throw Exception(
          'Error al obtener la URL de la imagen desde Firebase Storage: $e');
    }
  }

  Future<List<ServiceResponse>> fetchServicesFromBackend2(
      String token, String parentId) async {
    try {
      final String? token =
      await AuthUtils.getToken(); // Utiliza AuthUtils para obtener el token
      final response = await http.get(
        Uri.parse('$baseUrl/categories/parent/$parentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        if (responseData != null) {
          final List<ServiceResponse> services = responseData
              .map((data) => ServiceResponse.fromJson(data))
              .toList();
          return services;
        } else {
          throw Exception('La respuesta del backend está vacía.');
        }
      } else {
        throw Exception('Error al cargar los servicios desde el backend');
      }
    } catch (e) {
      throw Exception('Error al cargar los servicios desde el backend');
    }
  }

  void _logError(http.Response response) {
  }

  // Obtiene todas las ofertas de un worker
  Future<List<Map<String, dynamic>>> getOffersByWorkerId(String workerId) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    if (token == null) {
      throw Exception('Token de autenticación no disponible');
    }
    // 1. Obtener todos los servicios del worker
    final servicesUrl = Uri.parse('$baseUrl/services/byUserId?workerId=$workerId');
    final servicesResp = await http.get(
      servicesUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (servicesResp.statusCode != 200) {
      throw Exception('Error al cargar servicios del worker: \\${servicesResp.statusCode}');
    }
    final List services = json.decode(servicesResp.body) as List;
    List<Map<String, dynamic>> allOffers = [];

    // 2. Por cada servicio, obtener sus ofertas
    for (final service in services) {
      final serviceId = service['id'];
      final offersUrl = Uri.parse('$baseUrl/offers/$serviceId');
      final offersResp = await http.get(
        offersUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (offersResp.statusCode == 200) {
        final List offers = json.decode(offersResp.body) as List;
        allOffers.addAll(offers.map((e) => Map<String, dynamic>.from(e)));
      }
      // Si no hay ofertas para ese servicio, simplemente sigue
    }
    return allOffers;
  }

  // Obtiene las ofertas hechas por un worker específico (para Wallet)
  Future<List<Map<String, dynamic>>> getWorkerOffers(String workerId) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    if (token == null) {
      throw Exception('Token de autenticación no disponible');
    }
    try {
      // Usar un endpoint más específico que filtre por workerId en las ofertas
      final offersUrl = Uri.parse('$baseUrl/offers/byWorker?workerId=$workerId');
      final offersResp = await http.get(
        offersUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (offersResp.statusCode == 200) {
        final List offers = json.decode(offersResp.body) as List;
        return offers.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        // Si el endpoint específico no existe, usar el método anterior pero filtrar
        return await _getWorkerOffersAlternative(workerId);
      }
    } catch (e) {
      // Fallback al método anterior
      return await _getWorkerOffersAlternative(workerId);
    }
  }

  // Método alternativo para obtener ofertas del worker
  Future<List<Map<String, dynamic>>> _getWorkerOffersAlternative(String workerId) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    if (token == null) {
      throw Exception('Token de autenticación no disponible');
    }
    List<Map<String, dynamic>> workerOffers = [];

    try {
      // Obtener todas las ofertas y filtrar por workerId
      final allOffersUrl = Uri.parse('$baseUrl/offers');
      final allOffersResp = await http.get(
        allOffersUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (allOffersResp.statusCode == 200) {
        final List allOffers = json.decode(allOffersResp.body) as List;
        // Filtrar solo las ofertas hechas por este worker
        workerOffers = allOffers
            .where((offer) => offer['workerId'] == workerId)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
    }

    return workerOffers;
  }
}

class ServiceResponse {
  final String id;
  final String name;
  final String image;
  final String description;
  final List<ServiceType> serviceTypes;
  final String? parentId;
  final List<String> buttonTexts;
  final List<dynamic> priceRanges;
  final String typeName;

  ServiceResponse({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.serviceTypes,
    this.parentId,
    required this.buttonTexts,
    required this.priceRanges,
    required this.typeName,
  });

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> serviceTypesData = json['serviceTypes'] ?? [];
    final List<ServiceType> serviceTypes = serviceTypesData
        .map((data) => ServiceType(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      selectedDate: data['selectedDate'] ?? '',
      selectedTime: data['selectedTime'] ?? '',
    ))
        .toList();
    return ServiceResponse(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      serviceTypes: serviceTypes,
      parentId: json['parentId'] ??
          '', // Asegúrate de proporcionar un valor por defecto si es nulo
      buttonTexts: json['buttonTexts'] != null
          ? List<String>.from(json['buttonTexts'])
          : [],
      priceRanges: json['priceRanges'] != null
          ? List<dynamic>.from(json['priceRanges'])
          : [],
      typeName: json['typeName'] ?? '', // Corregido el nombre del campo
    );
  }
}
