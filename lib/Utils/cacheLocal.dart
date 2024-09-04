import 'dart:convert';

import 'package:socio/ServiceResponse/request.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  // Cachea una lista de solicitudes de servicio.
  static Future<void> cacheServiceRequests(List<ServiceRequest> serviceRequests) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String serviceRequestsJson = jsonEncode(
        serviceRequests.map((sr) => sr.toMap()).toList()
      );
      await prefs.setString('cached_service_requests', serviceRequestsJson);
    } catch (e) {
      print('Error al cachear los servicios: $e');
    }
  }

  // Obtiene la lista de solicitudes de servicio desde el caché.
  static Future<List<ServiceRequest>> getCachedServiceRequests() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? serviceRequestsJson = prefs.getString('cached_service_requests');
      if (serviceRequestsJson != null) {
        final List<dynamic> serviceRequestsList = jsonDecode(serviceRequestsJson) as List<dynamic>;
        return serviceRequestsList.map((item) => ServiceRequest.fromSnapshot(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('Error al obtener los servicios del caché: $e');
    }
    return [];
  }

  // Actualiza un solo servicio dentro de la lista cacheada.
  static Future<void> updateCachedServiceRequest(ServiceRequest updatedServiceRequest) async {
    try {
      List<ServiceRequest> cachedServiceRequests = await getCachedServiceRequests();
      final int index = cachedServiceRequests.indexWhere((sr) => sr.id == updatedServiceRequest.id);
      if (index != -1) {
        cachedServiceRequests[index] = updatedServiceRequest;
      } else {
        cachedServiceRequests.add(updatedServiceRequest);
      }
      await cacheServiceRequests(cachedServiceRequests);
    } catch (e) {
      print('Error al actualizar el servicio cacheado: $e');
    }
  }

  // Limpia los servicios cacheados de un usuario específico.
  static Future<void> clearCacheForUser(String userId) async {
    try {
      List<ServiceRequest> cachedServiceRequests = await getCachedServiceRequests();
      cachedServiceRequests.removeWhere((sr) => sr.userId == userId);
      await cacheServiceRequests(cachedServiceRequests);
    } catch (e) {
      print('Error al limpiar el caché para el usuario: $e');
    }
  }
}
