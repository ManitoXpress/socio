import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:http/http.dart' as http;
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/baseurl.dart';
import 'package:socio/ServiceResponse/request.dart';

class ApiService {
  final String baseUrl = ApiConfiguration.baseUrl;

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

  Future<http.Response> sendProposalToBackend(
      ServiceRequest serviceRequest, String token, String offeredPrice) async {
    try {
      final formData = {
        'serviceId':
            serviceRequest.id, // ID del servicio al que se hace la oferta
        'offeredPrice': offeredPrice,
      };

      final Uri url =
          Uri.parse('$baseUrl/offers?serviceId=${serviceRequest.id}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(formData),
      );

      if (response.statusCode == 201) {
        print('Oferta enviada con éxito al backend');
      } else {
        print('Solicitud HTTP fallida con código: ${response.statusCode}');
      }

      return response;
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      throw Exception('Error al enviar oferta al backend: $e');
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

  Future<http.Response> updateUser(
      String userId, RegistrationData registrationData, String token) async {
    try {
      // Mapea cada expertise a un mapa con nombre e ID
      List<Map<String, String>> expertises =
          registrationData.expertises.map((expertise) {
        return {
          'name': expertise.name,
          'id': expertise.id,
        };
      }).toList();

      Map<String, dynamic> requestBody = {
        'displayName': registrationData.displayName,
        'idCardNumber': registrationData.idCardNumber,
        'phoneNumber': FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        'location': registrationData.location ?? {},
        'paymentType': registrationData.paymentType,
        'imagePath': registrationData.imagePath,
        'idDocumentImagePath': registrationData.idDocumentImagePath,
        'idDocumentImagePath2': registrationData.idDocumentImagePath2,
        'criminalRecordImagePath': registrationData.criminalRecordImagePath,
        'certificateImagePaths': registrationData.certificateImagePaths,
        'expertises':
            expertises, // Aquí se pasa la lista de expertises con nombre e ID
        'expLevel': registrationData.expLevel,
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

  Future<void> uploadImageToFirebaseStorage(File image, String userId) async {
    try {
      print('Comenzando la carga de la imagen a Firebase Storage');

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        // Manejar el caso en el que el usuario no está autenticado
        print('Error: Usuario no autenticado.');
        return;
      }

      final FirebaseStorage storage = FirebaseStorage.instance;

      // Crear una carpeta específica para cada usuario
      String extension = image.path.split('.').last;
      String imageName =
          'profileImage_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Ruta de la carpeta del usuario
      String userFolderPath = '${user.uid}/';

      // Ruta completa de la imagen
      String imagePath = '$userFolderPath$imageName';

      // Verificar si el archivo de imagen existe antes de cargarlo
      if (await image.exists()) {
        // Obtener la referencia de la carpeta del usuario
        Reference userFolderRef = storage.ref().child(userFolderPath);

        // Verificar si la carpeta del usuario ya existe
        bool folderExists = false;
        try {
          await userFolderRef.getDownloadURL();
          folderExists = true;
        } catch (error) {
          // La carpeta no existe, y esto es normal
        }

        // Crear la carpeta del usuario si no existe
        if (!folderExists) {
          await userFolderRef.putData(Uint8List(0));
          print('Creada la carpeta del usuario en Firebase Storage');
        } else {
          print('La carpeta del usuario ya existe en Firebase Storage');
        }

        // Obtener la referencia de la imagen y subir el archivo
        Reference ref = storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');
      } else {
        print('Error: El archivo de imagen no existe.');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }

  Future<void> uploadImageToFirebaseStorage2(File image, String userId) async {
    try {
      print('Comenzando la carga de la imagen a Firebase Storage');

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        // Manejar el caso en el que el usuario no está autenticado
        print('Error: Usuario no autenticado.');
        return;
      }

      final FirebaseStorage storage = FirebaseStorage.instance;

      // Crear una carpeta específica para cada usuario
      String extension = image.path.split('.').last;
      String imageName =
          'IdentificactionNumber_A_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Ruta de la carpeta del usuario
      String userFolderPath = '${user.uid}/';

      // Ruta completa de la imagen
      String imagePath = '$userFolderPath$imageName';

      // Verificar si el archivo de imagen existe antes de cargarlo
      if (await image.exists()) {
        // Obtener la referencia de la carpeta del usuario
        Reference userFolderRef = storage.ref().child(userFolderPath);

        // Verificar si la carpeta del usuario ya existe
        bool folderExists = false;
        try {
          await userFolderRef.getDownloadURL();
          folderExists = true;
        } catch (error) {
          // La carpeta no existe, y esto es normal
        }

        // Crear la carpeta del usuario si no existe
        if (!folderExists) {
          await userFolderRef.putData(Uint8List(0));
          print('Creada la carpeta del usuario en Firebase Storage');
        } else {
          print('La carpeta del usuario ya existe en Firebase Storage');
        }

        // Obtener la referencia de la imagen y subir el archivo
        Reference ref = storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');
      } else {
        print('Error: El archivo de imagen no existe.');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }

  Future<void> uploadImageToFirebaseStorage3(File image, String userId) async {
    try {
      print('Comenzando la carga de la imagen a Firebase Storage');

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        // Manejar el caso en el que el usuario no está autenticado
        print('Error: Usuario no autenticado.');
        return;
      }

      final FirebaseStorage storage = FirebaseStorage.instance;

      // Crear una carpeta específica para cada usuario
      String extension = image.path.split('.').last;
      String imageName =
          'IdentificactionNumber_B_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Ruta de la carpeta del usuario
      String userFolderPath = '${user.uid}/';

      // Ruta completa de la imagen
      String imagePath = '$userFolderPath$imageName';

      // Verificar si el archivo de imagen existe antes de cargarlo
      if (await image.exists()) {
        // Obtener la referencia de la carpeta del usuario
        Reference userFolderRef = storage.ref().child(userFolderPath);

        // Verificar si la carpeta del usuario ya existe
        bool folderExists = false;
        try {
          await userFolderRef.getDownloadURL();
          folderExists = true;
        } catch (error) {
          // La carpeta no existe, y esto es normal
        }

        // Crear la carpeta del usuario si no existe
        if (!folderExists) {
          await userFolderRef.putData(Uint8List(0));
          print('Creada la carpeta del usuario en Firebase Storage');
        } else {
          print('La carpeta del usuario ya existe en Firebase Storage');
        }

        // Obtener la referencia de la imagen y subir el archivo
        Reference ref = storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');
      } else {
        print('Error: El archivo de imagen no existe.');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }

  Future<void> uploadImageToFirebaseStorage4(File image, String userId) async {
    try {
      print('Comenzando la carga de la imagen a Firebase Storage');

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        // Manejar el caso en el que el usuario no está autenticado
        print('Error: Usuario no autenticado.');
        return;
      }

      final FirebaseStorage storage = FirebaseStorage.instance;

      // Crear una carpeta específica para cada usuario
      String extension = image.path.split('.').last;
      String imageName =
          'criminalRecord_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Ruta de la carpeta del usuario
      String userFolderPath = '${user.uid}/';

      // Ruta completa de la imagen
      String imagePath = '$userFolderPath$imageName';

      // Verificar si el archivo de imagen existe antes de cargarlo
      if (await image.exists()) {
        // Obtener la referencia de la carpeta del usuario
        Reference userFolderRef = storage.ref().child(userFolderPath);

        // Verificar si la carpeta del usuario ya existe
        bool folderExists = false;
        try {
          await userFolderRef.getDownloadURL();
          folderExists = true;
        } catch (error) {
          // La carpeta no existe, y esto es normal
        }

        // Crear la carpeta del usuario si no existe
        if (!folderExists) {
          await userFolderRef.putData(Uint8List(0));
          print('Creada la carpeta del usuario en Firebase Storage');
        } else {
          print('La carpeta del usuario ya existe en Firebase Storage');
        }

        // Obtener la referencia de la imagen y subir el archivo
        Reference ref = storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen cargada con éxito en Firebase Storage');
        });

        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen en Firebase Storage: $imageUrl');
      } else {
        print('Error: El archivo de imagen no existe.');
      }
    } catch (e) {
      print('Error al cargar la imagen en Firebase Storage: $e');
      throw Exception('Error al cargar la imagen en Firebase Storage: $e');
    }
  }

  Future<void> uploadImageToFirebaseStorage5(
      List<File> images, String userId) async {
    try {
      print('Comenzando la carga de las imágenes a Firebase Storage');

      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user == null) {
        // Manejar el caso en el que el usuario no está autenticado
        print('Error: Usuario no autenticado.');
        return;
      }

      final FirebaseStorage storage = FirebaseStorage.instance;

      // Ruta de la carpeta del usuario
      String userFolderPath = '${user.uid}/';

      for (int i = 0; i < images.length; i++) {
        File image = images[i];

        // Crear un nombre único para cada imagen
        String extension = image.path.split('.').last;
        String imageName =
            'Certificate_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.$extension';

        // Ruta completa de la imagen
        String imagePath = '$userFolderPath$imageName';

        // Obtener la referencia de la imagen y subir el archivo
        Reference ref = storage.ref().child(imagePath);
        UploadTask uploadTask = ref.putFile(image);

        await uploadTask.whenComplete(() {
          print('Imagen ${i + 1} cargada con éxito en Firebase Storage');
        });

        final imageUrl = await ref.getDownloadURL();
        print('URL de la imagen ${i + 1} en Firebase Storage: $imageUrl');
      }

      print('Todas las imágenes cargadas con éxito en Firebase Storage');
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
