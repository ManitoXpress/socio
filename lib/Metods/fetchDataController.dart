import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:convert';

import 'package:socio/ServiceResponse/get.dart';

class ServiceDataFetcher {
  final ApiService2 apiService;

  ServiceDataFetcher(this.apiService);

  Future<List<Map<String, dynamic>>> fetchDataForUserId(
      String userId, List<String> expertisesLowerCase) async {
    try {
      // Obtén el usuario actualmente autenticado
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String? token = await user.getIdToken();

        String column = "";
        String value = "";
        String type = "";

        final Response serviceResponse =
            await apiService.fetchServicebyExpertises(
          userId,
          token!,
          column as List<String>,
        );

        if (serviceResponse.statusCode == 200) {
          final List<dynamic> jsonDataList = json.decode(serviceResponse.body);

          final List<Map<String, dynamic>> serviceRequestsList =
              jsonDataList.map((item) {
            final expertises = item['expertises'];
            final images = item['images'];

            return {
              'expertises':
                  expertises is List ? List<String>.from(expertises) : [],
              'id': item['id'],
              'dateTime': item['dateTime'],
              'description': item['description'],
              'images': images is List ? List<String>.from(images) : [],
              'location': Map<String, double>.from(item['location'] ?? {}),
              'offeredPrice': (item['offeredPrice'] as num?)?.toDouble() ?? 0.0,
              'userId': item['userId'],
              'status': item['status'],
              'isFavorite': item['isFavorite'] as bool? ?? false,
              'acceptedTerms': item['acceptedTerms'] as bool? ?? false,
              'serviceType': {
                'name': item['serviceType'],
                'id': '',
                'selectedDate': '',
                'selectedTime': '',
              }
            };
          }).toList();

          print(
              'Servicios cargados con éxito. Total de servicios obtenidos del backend: ${serviceRequestsList.length}');
          return serviceRequestsList;
        } else {
          print(
              'Error al obtener datos del backend. Código de estado: ${serviceResponse.statusCode}');
        }
      } else {
        print('Usuario no autenticado');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
    }
    // Si hay algún error o no se puede obtener la respuesta, retorna una lista vacía
    return [];
  }
}
