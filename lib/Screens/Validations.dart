import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/Screens/Home.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/authUtils.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/wizards/Certificates.dart';
import 'package:socio/wizards/CriminalRecords.dart';
import 'package:socio/wizards/DocumentB.dart';
import 'package:socio/wizards/IdDocument.dart';
import 'package:socio/wizards/Location.dart';
import 'package:socio/wizards/ProfileImage.dart';
import 'package:socio/wizards/ServiceTypeSelection.dart';
import 'package:socio/wizards/forms.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class RegistrationScreen extends StatefulWidget {
  final RegistrationController registrationController;
  final VoidCallback completeRegistrationCallback;
  final ApiService2 apiService2;
  RegistrationScreen({
    required this.registrationController,
    required this.completeRegistrationCallback,
    required this.apiService2,
  });

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int currentStep = 0;
  late ServiceDataWizard step1Data;
  late LocationAndFavoritesWizard step2Location;
  late ProfileImage step3ProfileImage;
  late ServiceTypeSelection step4ServiceType;
  LatLng? location;
  late IdCardImageStep step5IdCardImage;
  late IdCardImageStepB step5IdCardImageB;
  late CriminalRecordImageStep step7CriminalRecordImage;
  late CertificateImageStep step8CertificateImage;
  bool isStep1Complete = false;

  late RegistrationData registrationData;

  late RegistrationController registrationController;
  late UserData userData;
  String? fcmToken;

  // Bandera para controlar si el formulario ya se completó
  bool formCompleted = false;
  bool loadingCompleteRegistration = false;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getToken().then((value) {
      setState(() {
        fcmToken = value;
      });
    });

    // Restaura el estado del formulario
    restoreFormState();

    // Restaura la bandera del formulario completado
    restoreFormCompletedState();

    // Inicializa UserData, RegistrationData y RegistrationController aquí
    setState(() {
      registrationData = RegistrationData(
        userId: '',
        displayName: '',
        idCardNumber: '',
        phoneNumber: '',
        imagePath: '',
        paymentType: '',
        location: {},
        expertises: [],
        email: '',
        idDocumentImagePath: '',
        idDocumentImagePath2: '',
        imagePathList: [],
        criminalRecordImagePath: '',
        certificateImagePaths: '',
        expLevel: [],
        selectedCountryCode: '',
        devicesId: '',
        fcmToken: '',
      );

      userData = UserData(
        userId: '',
        displayName: '',
        idCardNumber: '',
        phoneNumber: '',
        location: null,
        imagePath: '',
        email: '',
        idDocumentImagePath: '',
        idDocumentImagePath2: '',
        paymentType: '',
        expertises: [],
        registrationData: registrationData,
        criminalRecordImagePath: '',
        pdfPathController: '',
        certificateImagePaths: '',
        expLevel: [],
        selectedCountryCode: '',
        getToken: '',
      );

      userData.imagePath = '';
      registrationController = widget.registrationController;

      step1Data = ServiceDataWizard(
        onNextStep: _nextStep,
        registrationData: registrationData,
        registrationController: registrationController,
        userData: userData,
      );
    });

    step2Location = LocationAndFavoritesWizard(
      onLocationSelected: (location) {
        setState(() {
          if (location != null) {
            userData.location = {
              'lat': location.latitude,
              'lng': location.longitude,
            };
          }
        });
      },
      onFavoritesSelected: (favorite) {
        // Puedes manejar si se selecciona como favorito, si es necesario
      },
      onNextStep: () {
        if (userData.location != null) {
          _nextStep();
        } else {
          // Mostrar mensaje o realizar alguna acción indicando que la ubicación es obligatoria.
          print('Selecciona una ubicación antes de pasar al siguiente paso.');
        }
      },
      registrationData: registrationData,
      registrationController: registrationController,
      userData: userData,
      location: {},
    );

    step3ProfileImage = ProfileImage(
      registrationController: registrationController,
      isImageCaptured: ValueNotifier<bool>(false),
      onNextStep: () {
        if (userData.imagePath.isNotEmpty) {
          _nextStep();
        } else {
          print('Selecciona una imagen antes de pasar al siguiente paso.');
        }
      },
      onImageSelected: (String imagePath) {
        // Actualiza la ruta de la imagen en userData
        userData.imagePath = imagePath;

        // También actualiza registrationData
        registrationData.imagePath = imagePath;
        print('Imagen seleccionada y asignada: $imagePath');

        // Actualiza la UI
        setState(() {});
      },
      registrationData: registrationData,
      userData: userData,
      imagePath: userData.imagePath,
    );

    step4ServiceType = ServiceTypeSelection(
      onNextStep: () {
        // Implementa lo que sea necesario
      },
      registrationController: registrationController,
      onServiceTypeSelected: (serviceType) {
        // Implementa lo que sea necesario
      },
      fetchExpertises: widget.apiService2.fetchExpertises,
      onServiceTypesSelected:
          (List<Expertise> expertises, String? selectedExperienceLevel) {
        setState(() {
          // Crear una lista de Expertises a partir de los nombres seleccionados
          userData.expertises = expertises;
          userData.expLevel =
              selectedExperienceLevel != null ? [selectedExperienceLevel] : [];
        });
        print('Selected Expertises: $expertises');
        print('Selected Experience Level: $selectedExperienceLevel');
      },
    );

    step5IdCardImage = IdCardImageStep(
      registrationController: registrationController,
      isImageCaptured: ValueNotifier<bool>(false),
      onNextStep: () {
        if (userData.idDocumentImagePath.isNotEmpty) {
          _nextStep();
        } else {
          print('Selecciona una imagen antes de pasar al siguiente paso.');
        }
      },
      onImageSelected: (String idDocumentImagePath) {
        // Actualiza la ruta de la imagen en userData
        userData.idDocumentImagePath = idDocumentImagePath;

        // También actualiza registrationData
        registrationData.idDocumentImagePath = idDocumentImagePath;
        print('Imagen seleccionada y asignada: $idDocumentImagePath');

        // Actualiza la UI
        setState(() {});
      },
      registrationData: registrationData,
      userData: userData,
      idDocumentImagePath: userData.idDocumentImagePath,
    );

    step5IdCardImageB = IdCardImageStepB(
      registrationController: registrationController,
      isImageCaptured: ValueNotifier<bool>(false),
      onNextStep: () {
        if (userData.idDocumentImagePath2.isNotEmpty) {
          _nextStep();
        } else {
          print('Selecciona una imagen antes de pasar al siguiente paso.');
        }
      },
      onImageSelected: (String idDocumentImagePath2) {
        // Actualiza la ruta de la imagen en userData
        userData.idDocumentImagePath2 = idDocumentImagePath2;

        // También actualiza registrationData
        registrationData.idDocumentImagePath = idDocumentImagePath2;
        print('Imagen seleccionada y asignada: $idDocumentImagePath2');

        // Actualiza la UI
        setState(() {});
      },
      registrationData: registrationData,
      userData: userData,
      idDocumentImagePath2: userData.idDocumentImagePath2,
    );

    step7CriminalRecordImage = CriminalRecordImageStep(
      registrationController: registrationController,
      isImageCaptured: ValueNotifier<bool>(false),
      onNextStep: () {
        if (userData.criminalRecordImagePath.isNotEmpty) {
          _nextStep();
        } else {
          print('Selecciona una imagen antes de pasar al siguiente paso.');
        }
      },
      onImageSelected: (String criminalRecordImagePath) {
        // Actualiza la ruta de la imagen en userData
        userData.criminalRecordImagePath = criminalRecordImagePath;

        // También actualiza registrationData
        registrationData.idDocumentImagePath = criminalRecordImagePath;
        print('Imagen seleccionada y asignada: $criminalRecordImagePath');

        // Actualiza la UI
        setState(() {});
      },
      registrationData: registrationData,
      userData: userData,
      criminalRecordImagePath: userData.criminalRecordImagePath,
    );

    step8CertificateImage = CertificateImageStep(
      registrationController: registrationController,
      isImageCaptured: ValueNotifier<bool>(false),
      onNextStep: () {
        if (userData.certificateImagePaths.isNotEmpty) {
          _nextStep();
        } else {
          print('Selecciona una imagen antes de pasar al siguiente paso.');
        }
      },
      onImageSelected: (String certificateImagePaths) {
        // Actualiza la ruta de la imagen en userData
        userData.certificateImagePaths = certificateImagePaths;

        // También actualiza registrationData
        registrationData.certificateImagePaths = certificateImagePaths;
        print('Imagen seleccionada y asignada: $certificateImagePaths');

        // Actualiza la UI
        setState(() {});
      },
      registrationData: registrationData,
      userData: userData,
      certificateImagePaths: userData.certificateImagePaths,
    );
  }

  void restoreFormState() {
    // Lógica para cargar datos previos del formulario si es necesario
  }

  void restoreFormCompletedState() {
    // Lógica para cargar el estado de la bandera si es necesario
  }

  void _nextStep() {
    // Validar el paso 3 (ProfileImage)
    if (currentStep == 2) {
      if (userData.imagePath.isEmpty) {
        print('Selecciona una imagen antes de pasar al siguiente paso.');
        return;
      }
    }

    // Validar el paso 4 (ServiceType)
    if (currentStep == 3) {
      if (userData.expertises.isEmpty || userData.expLevel.isEmpty) {
        print(
            'Selecciona un tipo de servicio y un nivel de experiencia antes de pasar al siguiente paso.');
        return;
      }
    }

    // Validar el paso 5 (IdCardImageStep)
    if (currentStep == 4) {
      if (userData.idDocumentImagePath.isEmpty) {
        print(
            'Selecciona una imagen del documento de identidad antes de pasar al siguiente paso.');
        return;
      }
    }

    // Validar el paso 6 (IdCardImageStepB)
    if (currentStep == 5) {
      if (userData.idDocumentImagePath2.isEmpty) {
        print(
            'Selecciona una segunda imagen del documento de identidad antes de pasar al siguiente paso.');
        return;
      }
    }
    // Si todos los pasos anteriores son válidos, avanza al siguiente paso
    setState(() {
      if (currentStep < 7) {
        currentStep += 1;
      }
    });
  }

  Future<String?> _uploadImage(
      File imageFile, String userId, String imageType) async {
    try {
      final apiService = ApiService();
      User? user = FirebaseAuth.instance.currentUser;
      if (imageFile.existsSync()) {
        // Comprimir y redimensionar la imagen antes de subirla
        final compressedFile = await compressAndResizeImage(imageFile);

        // Subir la imagen y obtener la URL de descarga
        String imageUrl;
        switch (imageType) {
          case 'profile':
            imageUrl = await apiService.uploadImageToFirebaseStorage(
                compressedFile, userId);
            break;
          case 'idDocument1':
            imageUrl = await apiService.uploadImageToFirebaseStorage2(
                compressedFile, userId);
            break;
          case 'idDocument2':
            imageUrl = await apiService.uploadImageToFirebaseStorage3(
                compressedFile, userId);
            break;
          case 'criminalRecord':
            imageUrl = await apiService.uploadImageToFirebaseStorage4(
                compressedFile, userId);
            break;
          case 'certificate':
            imageUrl = (await apiService.uploadImageToFirebaseStorage5(
                [compressedFile], userId)) as String;
            break;
          default:
            return null;
        }

        print('URL de la imagen cargada ($imageType): $imageUrl');
        return imageUrl;
      } else {
        print(
            'Advertencia: La imagen no existe en la ruta proporcionada para $imageType.');
        return null;
      }
    } catch (e) {
      print('Error al cargar la imagen ($imageType): $e');
      return null;
    }
  }

  Future<File> compressAndResizeImage(File image) async {
    // Leer el archivo de imagen
    final originalImage = img.decodeImage(image.readAsBytesSync());

    // Redimensionar la imagen para reducir aún más su tamaño
    final resizedImage = img.copyResize(originalImage!,
        width: 600); // Cambia el tamaño según sea necesario

    // Comprimir la imagen redimensionada
    final compressedImage = img.encodeJpg(resizedImage,
        quality: 50); // Baja la calidad si es necesario

    // Obtener el directorio temporal
    final tempDir = await getTemporaryDirectory();

    // Guardar la imagen comprimida y redimensionada en un archivo temporal
    final compressedFile = File(
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    compressedFile.writeAsBytesSync(compressedImage);

    return compressedFile;
  }

  Future<void> _completeRegistration() async {
    print('Entrando a _completeRegistration');

    try {
      final apiService = ApiService();
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        registrationData.userId = user.uid;
        registrationData.location = {
          'lat': location?.latitude ?? 0.0,
          'lng': location?.longitude ?? 0.0,
        };
        registrationData.expertises = userData.expertises;
        registrationData.expLevel = userData.expLevel;
        registrationData.paymentType = userData.paymentType;
        registrationData.phoneNumber =
            userData.phoneNumber; // Se añade el número de teléfono
// Subir la imagen de perfil directamente desde `registrationData.imagePath`
        if (registrationData.imagePath.isNotEmpty) {
          File image = File(registrationData.imagePath);

          if (image.existsSync()) {
            try {
              final compressedFile = await compressAndResizeImage(image);
              final String imageUrl = await apiService
                  .uploadImageToFirebaseStorage(compressedFile, user.uid);
              registrationData.imagePath = imageUrl.endsWith('/')
                  ? imageUrl.substring(0, imageUrl.length - 1)
                  : imageUrl;
              print(
                  'URL de la imagen de perfil: ${registrationData.imagePath}');
            } catch (e) {
              print('Error al cargar la imagen de perfil: $e');
            }
          } else {
            print(
                'Advertencia: La imagen de perfil no existe en la ruta proporcionada.');
          }
        } else {
          print('Advertencia: No se proporcionó ninguna imagen de perfil.');
        }

        // Manejo de las imágenes de documento de identificación
        if (registrationData.idDocumentImagePath.isNotEmpty) {
          File idDocImage = File(registrationData.idDocumentImagePath);

          if (idDocImage.existsSync()) {
            try {
              final compressedFile = await compressAndResizeImage(idDocImage);
              final String idDocImageUrl = await apiService
                  .uploadImageToFirebaseStorage(compressedFile, user.uid);
              registrationData.idDocumentImagePath = idDocImageUrl;
              print(
                  'URL de la primera imagen de documento de identificación: $idDocImageUrl');
            } catch (e) {
              print(
                  'Error al cargar la primera imagen de documento de identificación: $e');
            }
          } else {
            print(
                'Advertencia: La primera imagen de documento no existe en la ruta proporcionada.');
          }
        } else {
          print(
              'Advertencia: No se proporcionó ninguna imagen de documento de identificación.');
        }

        if (registrationData.idDocumentImagePath2.isNotEmpty) {
          File idDocImage2 = File(registrationData.idDocumentImagePath2);

          if (idDocImage2.existsSync()) {
            try {
              final compressedFile = await compressAndResizeImage(idDocImage2);
              final String idDocImageUrl2 = await apiService
                  .uploadImageToFirebaseStorage(compressedFile, user.uid);
              registrationData.idDocumentImagePath2 = idDocImageUrl2;
              print(
                  'URL de la segunda imagen de documento de identificación: $idDocImageUrl2');
            } catch (e) {
              print(
                  'Error al cargar la segunda imagen de documento de identificación: $e');
            }
          } else {
            print(
                'Advertencia: La segunda imagen de documento no existe en la ruta proporcionada.');
          }
        } else {
          print(
              'Advertencia: No se proporcionó la segunda imagen de documento de identificación.');
        }

        // Subir certificados
        if (registrationData.certificateImagePaths.isNotEmpty) {
          File idDocImage2 = File(registrationData.certificateImagePaths);

          if (idDocImage2.existsSync()) {
            try {
              final compressedFile = await compressAndResizeImage(idDocImage2);
              final String idDocImageUrl2 = await apiService
                  .uploadImageToFirebaseStorage(compressedFile, user.uid);
              registrationData.certificateImagePaths = idDocImageUrl2;
              print(
                  'URL de la segunda imagen de documento de identificación: $idDocImageUrl2');
            } catch (e) {
              print(
                  'Error al cargar la segunda imagen de documento de identificación: $e');
            }
          } else {
            print(
                'Advertencia: La segunda imagen de documento no existe en la ruta proporcionada.');
          }
        } else {
          print(
              'Advertencia: No se proporcionó la segunda imagen de documento de identificación.');
        }
        if (registrationData.criminalRecordImagePath.isNotEmpty) {
          File idDocImage2 = File(registrationData.criminalRecordImagePath);

          if (idDocImage2.existsSync()) {
            try {
              final compressedFile = await compressAndResizeImage(idDocImage2);
              final String idDocImageUrl2 = await apiService
                  .uploadImageToFirebaseStorage(compressedFile, user.uid);
              registrationData.criminalRecordImagePath = idDocImageUrl2;
              print(
                  'URL de la segunda imagen de documento de identificación: $idDocImageUrl2');
            } catch (e) {
              print(
                  'Error al cargar la segunda imagen de documento de identificación: $e');
            }
          } else {
            print(
                'Advertencia: La segunda imagen de documento no existe en la ruta proporcionada.');
          }
        } else {
          print(
              'Advertencia: No se proporcionó la segunda imagen de documento de identificación.');
        }

        String? devicesId = await AuthUtils.getDeviceId();
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // Actualizar el registro del usuario con las nuevas URLs de Firebase
        registrationData = RegistrationData.fromForm(
          userId: user.uid,
          displayName: userData.displayName,
          idCardNumber: userData.idCardNumber,
          phoneNumber: userData.phoneNumber,
          imagePath: registrationData.imagePath,
          location: userData.location,
          idDocumentImagePath: registrationData.idDocumentImagePath,
          idDocumentImagePath2: registrationData.idDocumentImagePath2,
          paymentType: userData.paymentType,
          expertises: userData.expertises,
          selectedCountryCode: userData.selectedCountryCode,
          expLevel: userData.expLevel,
          email: userData.email,
          imagePathList: [],
          criminalRecordImagePath: registrationData.criminalRecordImagePath,
          certificateImagePaths: registrationData.certificateImagePaths,
          devicesId: devicesId ?? '',
          fcmToken: fcmToken ?? '',
        );

        print('Después de RegistrationData.fromForm:');
        String? token = await user.getIdToken();

        final response = await apiService.updateUser(
          user.uid,
          registrationData,
          token!,
        );

        widget.completeRegistrationCallback();

        if (response.statusCode == 200) {
          print('Usuario actualizado con éxito');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          print('Error en la respuesta del servidor: ${response.statusCode}');
        }
      } else {
        print(
            'Advertencia: usuario es nulo. Asegúrate de que el usuario esté autenticado correctamente.');
      }
    } catch (error) {
      print('Error durante el proceso de registro: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registro de Usuario',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (currentStep == 0) ...[
              step1Data,
            ] else if (currentStep == 1) ...[
              step2Location,
            ] else if (currentStep == 2) ...[
              step3ProfileImage,
            ] else if (currentStep == 3) ...[
              step4ServiceType,
            ] else if (currentStep == 4) ...[
              step5IdCardImage,
            ] else if (currentStep == 5) ...[
              step5IdCardImageB,
            ] else if (currentStep == 6) ...[
              step7CriminalRecordImage,
            ] else if (currentStep == 7) ...[
              step8CertificateImage,
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loadingCompleteRegistration
                  ? null // Deshabilita el botón si está cargando
                  : () {
                      if (currentStep == 7) {
                        setState(() {
                          loadingCompleteRegistration = true;
                        });

                        // Mostrar diálogo de carga
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          // Evita que se cierre el diálogo al tocar fuera
                          builder: (context) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text(
                                    'Por favor, espere mientras completamos el registro...',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        );

                        // Completar el registro
                        _completeRegistration().then((_) {
                          setState(() {
                            loadingCompleteRegistration = false;
                          });
                          Navigator.of(context).pop(); // Cierra el diálogo

                          // Navegar a la siguiente pantalla
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HomeScreen(), // Cambiar por la pantalla correspondiente
                            ),
                          );
                        }).catchError((error) {
                          setState(() {
                            loadingCompleteRegistration = false;
                          });
                          Navigator.of(context).pop(); // Cierra el diálogo

                          // Mostrar mensaje de error
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Error'),
                                content: Text(
                                    'Ocurrió un error al completar el registro. Por favor, inténtelo de nuevo.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Aceptar'),
                                  ),
                                ],
                              );
                            },
                          );
                        });
                      } else {
                        _nextStep();
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Color(0xFF84090D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(
                    color: Color(0xFF84090D),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!loadingCompleteRegistration)
                      Text(
                        currentStep == 7
                            ? 'Completar Registro'
                            : 'Siguiente Paso',
                        style: MyTextStyles.buttonTextStyle.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    if (loadingCompleteRegistration)
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
