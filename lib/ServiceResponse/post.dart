import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:socio/Controller/RegisController.dart';
import 'package:socio/ServiceResponse/baseurl.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
class ApiService {
  final String baseUrl = ApiConfiguration.baseUrl;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<http.Response> sendTokenAndUserDataToServer({
    required String? token,
    required String? displayName,
    required String? email,
    required String? phoneNumber,
    required String? imagePath,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/workers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      print('Error al enviar datos al servidor: $e');
      throw Exception('Error al enviar datos al servidor: $e');
    }
  }
  Future<bool> checkProposalExists(String serviceId, String workerId) async {
    try {
      // Intentar obtener un token actualizado
      String token = await FirebaseAuth.instance.currentUser?.getIdToken(true) ?? '';

      if (token.isEmpty) {
        print('Error: No se pudo renovar el token de autenticación.');
        throw Exception('No se ha proporcionado un token de autenticación válido.');
      }

      // Asegúrate de que tu endpoint retorne correctamente las ofertas filtradas
      final response = await http.get(
        Uri.parse('$baseUrl/offers?serviceId=$serviceId&workerId=$workerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Respuesta de verificación: $data'); // Para depuración
        List<dynamic> offers = data is List ? data : (data['offers'] ?? []);
        return offers.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error al verificar oferta existente: $e');
      return false;
    }
  }

  Future<http.Response> sendTokenToServer(String? token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workers'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      print('Error al enviar token al servidor: $e');
      throw Exception('Error al enviar token al servidor: $e');
    }
  }

  Future<void> uploadImageToBackend(String imagePath, String serviceId, String token) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/media/upload/$serviceId'));
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        print('Imagen subida exitosamente');
      } else {
        print('Error al subir la imagen: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error al subir la imagen: $e');
    }
  }


  Future<http.Response> sendProposalToServer(
      ServiceRequest serviceRequest,
      String token,
      String offeredPrice,
      double extraCosts,
      String workerId,
      ) async {
    try {
      if (workerId.isEmpty) {
        print('workerId es nulo o vacío');
        throw Exception('workerId es nulo o vacío');
      }

      // Intentar obtener un nuevo token autenticado de Firebase
      String newToken = await FirebaseAuth.instance.currentUser?.getIdToken(true) ?? '';

      if (newToken.isEmpty) {
        print('Error: No se pudo renovar el token de autenticación.');
        throw Exception('No se ha proporcionado un token de autenticación válido.');
      }

      double offeredPriceValue = double.tryParse(offeredPrice) ?? 0.0;
      double totalPrice = offeredPriceValue + extraCosts;

      final proposalData = {
        'serviceId': serviceRequest.id,
        'offeredPrice': offeredPriceValue,
        'extraCosts': extraCosts,
        'totalPrice': totalPrice,
        'workerId': workerId,
        'status': 'offer',
        'hasOffer': true,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/offers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $newToken', // Usar el nuevo token autenticado
        },
        body: jsonEncode(proposalData),
      );

      if (response.statusCode == 201) {
        print('Oferta enviada con éxito al servidor');
      } else {
        print('Error al enviar oferta al servidor: ${response.body}');
        throw Exception('Error al enviar oferta al servidor: ${response.body}');
      }

      return response;
    } catch (e) {
      print('Error al enviar oferta al servidor: $e');
      throw Exception('Error al enviar oferta al servidor: $e');
    }
  }



  Future<http.Response> updateOfferStatus(String serviceId, String status, String token) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/offers/$serviceId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    return response;
  }

  // Método para actualizar un servicio
  Future<http.Response> updateServiceStatus(String serviceId, String status, String token) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/services/$serviceId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    return response;
  }


  Future<http.Response> updateUser(
      String userId,
      RegistrationData registrationData,
      String token,
      ) async {
    try {
      // Generar un código de referido único
      String codeReferral =
          '${registrationData.displayName.split(' ').first}_${registrationData.idCardNumber.length >= 4 ? registrationData.idCardNumber.substring(registrationData.idCardNumber.length - 4) : registrationData.idCardNumber}';

      // Mapear expertises a lista de mapas { name, id }
      List<Map<String, String>> expertises = registrationData.expertises
          .map((e) => {
        'name': e.name,
        'id': e.id,
      })
          .toList();

      // Si ahora manejas múltiples certificados en un CSV, convertimos a lista
      List<String> certificatePathsList = registrationData.certificateImagePaths;

      // Cuerpo de la petición
      final requestBody = <String, dynamic>{
        'displayName': registrationData.displayName,
        'idCardNumber': registrationData.idCardNumber,
        'phoneNumber': registrationData.phoneNumber,
        'location': registrationData.location,
        'paymentType': registrationData.paymentType,
        'imagePath': registrationData.imagePath,
        'idDocumentImagePath': registrationData.idDocumentImagePath,
        'idDocumentImagePath2': registrationData.idDocumentImagePath2,
        'criminalRecordImagePath': registrationData.criminalRecordImagePath,

        // Enviamos ahora la lista de certificados
        'certificateImagePaths': certificatePathsList,

        // Nuevo campo para Título Profesional / Matrícula
        'professionalTitleImagePath': registrationData.professionalTitleImagePath,

        'deviceId': registrationData.devicesId,
        'fcmToken': registrationData.fcmToken,
        'expertises': expertises,
        'expLevel': registrationData.expLevel,
        'verificationStatus': 'No verificado',
        'points': registrationData.points,
        'successfulReferrals': 0,
        'codeReferral': codeReferral,
        'requiresInvoice': registrationData.requiresInvoice ?? 'NO',
      };

      print('Request Body: $requestBody');

      final response = await http.patch(
        Uri.parse('$baseUrl/workers/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return response;
    } catch (e) {
      print('Error al actualizar el usuario: $e');
      throw Exception('Error al actualizar el usuario: $e');
    }
  }
  Future<http.Response> updateUserFields(
      String userId,
      Map<String, dynamic> fields,
      String token,
      ) async {
    final url = Uri.parse('$baseUrl/workers/$userId');
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(fields),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
    return response;
  }


  Future<String> uploadImageToFirebaseStorage(File image, String userId) async {
    try {
      final String extension = image.path.split('.').last;
      final String imageName =
          'userID_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String userFolderPath = '$userId/';  // Agregar barra al final
      final String imagePath = '$userFolderPath$imageName';
      // Concatenar correctamente

      if (await image.exists()) {
        Reference ref = storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');
        return imageUrl;
      } else {
        throw Exception('El archivo de imagen no existe.');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }




  Future<String> uploadImageToFirebaseStorage2(File image, String userId) async {
    try {
      print('Comenzando la carga de la imagen a Firebase Storage');

      // Crear una extensión basada en el nombre del archivo de imagen
      final String extension = image.path.split('.').last;

      // Crear un nombre único para la imagen usando la fecha actual
      final String imageName = 'IdentificactionNumber_A_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Crear la ruta de la carpeta del usuario
      final String userFolderPath = '$userId/';
      final String imagePath = '$userFolderPath$imageName';

      // Verificar si el archivo de imagen existe antes de cargarlo
      if (await image.exists()) {
        // Obtener la referencia de la imagen y subir el archivo
        final Reference ref = FirebaseStorage.instance.ref().child(imagePath);
        final UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        // Obtener la URL de descarga de la imagen cargada
        final String imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');

        return imageUrl; // Devolver la URL de la imagen
      } else {
        throw Exception('El archivo de imagen no existe.');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }

  Future<String> uploadImageToFirebaseStorage3(File image, String userId) async {
    try {
      print('Comenzando la carga de la imagen a Firebase Storage');

      // Crear una extensión basada en el nombre del archivo de imagen
      final String extension = image.path.split('.').last;

      // Crear un nombre único para la imagen usando la fecha actual
      final String imageName = 'IdentificactionNumber_B_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Crear la ruta de la carpeta del usuario
      final String userFolderPath = '$userId/';
      final String imagePath = '$userFolderPath$imageName';

      // Verificar si el archivo de imagen existe antes de cargarlo
      if (await image.exists()) {
        // Obtener la referencia de la imagen y subir el archivo
        final Reference ref = FirebaseStorage.instance.ref().child(imagePath);
        final UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        // Obtener la URL de descarga de la imagen cargada
        final String imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');

        return imageUrl; // Devolver la URL de la imagen
      } else {
        throw Exception('El archivo de imagen no existe.');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }
  Future<String> uploadImageToFirebaseStorage4(
      File image, String userId) async {
    try {
      print('Comenzando la carga de la imagen a Firebase Storage');

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        print('Error: Usuario no autenticado.');
        throw Exception('Usuario no autenticado');
      }

      final FirebaseStorage storage = FirebaseStorage.instance;

      String extension = image.path.split('.').last;
      String imageName =
          'certificate_${DateTime.now().millisecondsSinceEpoch}.$extension';
      String userFolderPath = '$userId/';
      String imagePath = '$userFolderPath$imageName';

      if (await image.exists()) {
        Reference ref = storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');
        return imageUrl;
      } else {
        print('Error: El archivo de imagen no existe.');
        throw Exception('El archivo de imagen no existe');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }
  Future<String> uploadImageToFirebaseStorage5(
      File image, String userId) async {
    try {
      print('Comenzando la carga de la imagen a Firebase Storage');

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        print('Error: Usuario no autenticado.');
        throw Exception('Usuario no autenticado');
      }

      final FirebaseStorage storage = FirebaseStorage.instance;

      String extension = image.path
          .split('.')
          .last;
      String imageName =
          'criminalRecord_${DateTime
          .now()
          .millisecondsSinceEpoch}.$extension';
      String userFolderPath = '$userId/';
      String imagePath = '$userFolderPath$imageName';

      if (await image.exists()) {
        Reference ref = storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');
        return imageUrl;
      } else {
        print('Error: El archivo de imagen no existe.');
        throw Exception('El archivo de imagen no existe');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }
  Future<String> uploadImageToFirebaseStorage6(
      File image, String userId) async {
    try {
      print('Comenzando la carga de la imagen a Firebase Storage');

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        print('Error: Usuario no autenticado.');
        throw Exception('Usuario no autenticado');
      }

      final FirebaseStorage storage = FirebaseStorage.instance;

      String extension = image.path
          .split('.')
          .last;
      String imageName =
          'medicalLicense_${DateTime
          .now()
          .millisecondsSinceEpoch}.$extension';
      String userFolderPath = '$userId/';
      String imagePath = '$userFolderPath$imageName';

      if (await image.exists()) {
        Reference ref = storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');
        return imageUrl;
      } else {
        print('Error: El archivo de imagen no existe.');
        throw Exception('El archivo de imagen no existe');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }
  Future<String> uploadImageToFirebaseStorage7(
      File image, String userId) async {
    try {
      print('Comenzando la carga de la imagen a Firebase Storage');

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        print('Error: Usuario no autenticado.');
        throw Exception('Usuario no autenticado');
      }

      final FirebaseStorage storage = FirebaseStorage.instance;

      String extension = image.path
          .split('.')
          .last;
      String imageName =
          'professionalTitle_${DateTime
          .now()
          .millisecondsSinceEpoch}.$extension';
      String userFolderPath = '$userId/';
      String imagePath = '$userFolderPath$imageName';

      if (await image.exists()) {
        Reference ref = storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');
        return imageUrl;
      } else {
        print('Error: El archivo de imagen no existe.');
        throw Exception('El archivo de imagen no existe');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }
}

class FormData {
  final String dateTime;
  final String description;
  final List<String> images;
  final Map<String, double> location;
  final int offeredPrice;
  final String serviceType; // Cambiar a String
  final String userId;

  FormData({
    required this.dateTime,
    required this.description,
    required this.images,
    required this.location,
    required this.offeredPrice,
    required this.serviceType, // Cambiar el tipo a String
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
    'dateTime': dateTime,
    'description': description,
    'images': images,
    'location': {
    'lat': location['lat'],
    'lng': location['lng'],
    },
    'offeredPrice': offeredPrice,
    'serviceType': serviceType, // Usar la cadena en lugar de un objeto ServiceType
    'userId': userId,
      };
    }
}