import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/baseurl.dart';
import 'package:socio/ServiceResponse/request.dart';

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

  Future<void> sendProposalToFirestore(
      ServiceRequest serviceRequest,
      String token,
      String offeredPrice,
      String workerId // Añade el workerId como parámetro
      ) async {
    try {
      // Obtén una referencia a la colección "offers"
      final offersCollection = FirebaseFirestore.instance.collection('offers');

      // Crea un documento con una propuesta en la colección "offers"
      final newProposalRef = offersCollection
          .doc(); // Crea un nuevo documento con un ID generado automáticamente

      // Define los datos de la propuesta
      final proposalData = {
        'serviceId':
            serviceRequest.id, // ID del servicio al que se hace la oferta
        'offeredPrice': offeredPrice,
        'createdAt':
            FieldValue.serverTimestamp(), // Marca de tiempo para la propuesta
        'userToken':
            token, // Token del usuario, si necesitas almacenar esta información
        'workerId': workerId, // Añade el workerId a los datos de la propuesta
      };

      // Guarda la propuesta en Firestore
      await newProposalRef.set(proposalData);

      print('Oferta enviada con éxito a Firestore');
    } catch (e) {
      print('Error al enviar oferta a Firestore: $e');
      throw Exception('Error al enviar oferta a Firestore: $e');
    }
  }

  Future<void> updateServiceStatus(
      String serviceRequestId, String newStatus, String token) async {
    try {
      final String? refreshedToken =
          await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final response = await http.patch(
        Uri.parse(
            '$baseUrl/services/$serviceRequestId'), // URL del servicio específico
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${refreshedToken ?? token}',
        },
        body: jsonEncode({'status': newStatus}), // Campo que deseas actualizar
      );

      if (response.statusCode == 200) {
        print('Estado actualizado con éxito en el backend');
      } else {
        print(
            'Error al actualizar el estado en el backend. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al realizar la solicitud HTTP de actualización: $e');
      throw Exception('Error al actualizar el estado en el backend');
    }
  }

  Future<http.Response> updateUser(String userId, RegistrationData registrationData, String token) async {
    try {
      // Asegúrate de que el campo imagePath tenga la URL de Firebase sin modificaciones
      String imagePath = registrationData.imagePath; // Verificamos que esta URL no esté anidada

      // Mapea cada expertise a un mapa con nombre e ID
      List<Map<String, String>> expertises = registrationData.expertises.map((expertise) {
        return {
          'name': expertise.name,
          'id': expertise.id,
        };
      }).toList();

      // Cuerpo de la solicitud
      Map<String, dynamic> requestBody = {
        'displayName': registrationData.displayName,
        'idCardNumber': registrationData.idCardNumber,
        'phoneNumber': FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        'location': registrationData.location ?? {},
        'paymentType': registrationData.paymentType,
        'imagePath': imagePath, // Asigna directamente la URL generada correctamente
        'idDocumentImagePath': registrationData.idDocumentImagePath,
        'idDocumentImagePath2': registrationData.idDocumentImagePath2,
        'criminalRecordImagePath': registrationData.criminalRecordImagePath,
        'certificateImagePaths': registrationData.certificateImagePaths,
        'expertises': expertises,
        'expLevel': registrationData.expLevel,
      };

      print('Request Body: $requestBody');

      // Enviar solicitud PATCH
      final response = await http.patch(
        Uri.parse('$baseUrl/workers/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody), // No modificar la URL aquí
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return response;
    } catch (e) {
      print('Error al actualizar el usuario: $e');
      throw Exception('Error al actualizar el usuario: $e');
    }
  }
  Future<String> uploadImageToFirebaseStorage(File image, String userId) async {
    try {
      final String extension = image.path.split('.').last;
      final String imageName = 'userID_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String userFolderPath = '$userId/';
      final String imagePath = '$userFolderPath$imageName';

      if (await image.exists()) {
        Reference ref = storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        // Aquí obtenemos la URL final de Firebase Storage
        final String imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');

        return imageUrl;  // Aquí retornamos la URL sin modificar
      } else {
        throw Exception('El archivo de imagen no existe.');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }




  Future<String> uploadImageToFirebaseStorage2(
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
          'IdentificactionNumber_A_${DateTime.now().millisecondsSinceEpoch}.$extension';
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
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }

  Future<String> uploadImageToFirebaseStorage3(
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
          'IdentificactionNumber_B_${DateTime.now().millisecondsSinceEpoch}.$extension';
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
          'criminalRecord_${DateTime.now().millisecondsSinceEpoch}.$extension';
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
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }

  Future<List<String>> uploadImageToFirebaseStorage5(
      List<File> images, String userId) async {
    try {
      print('Comenzando la carga de las imágenes a Firebase Storage');

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        print('Error: Usuario no autenticado.');
        throw Exception('Usuario no autenticado');
      }

      final FirebaseStorage storage = FirebaseStorage.instance;
      String userFolderPath = '$userId/';
      List<String> imageUrls = [];

      for (int i = 0; i < images.length; i++) {
        File image = images[i];
        String extension = image.path.split('.').last;
        String imageName =
            'Certificate_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        String imagePath = '$userFolderPath$imageName';

        if (await image.exists()) {
          Reference ref = storage.ref().child(imagePath);
          UploadTask uploadTask = ref.putFile(image);

          await uploadTask.whenComplete(() {
            print('Imagen ${i + 1} cargada con éxito en Firebase Storage');
          });

          final imageUrl = await ref.getDownloadURL();
          print('URL de la imagen ${i + 1} en Firebase Storage: $imageUrl');
          imageUrls.add(imageUrl);
        } else {
          print('Error: El archivo de imagen no existe.');
          throw Exception('El archivo de imagen no existe');
        }
      }

      print('Todas las imágenes cargadas con éxito en Firebase Storage');
      return imageUrls;
    } catch (e) {
      print('Error al cargar las imágenes en Firebase Storage: $e');
      throw Exception('Error al cargar las imágenes en Firebase Storage: $e');
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
      'serviceType':
          serviceType, // Usar la cadena en lugar de un objeto ServiceType
      'userId': userId,
    };
  }
}
