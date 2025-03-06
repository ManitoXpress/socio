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
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
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

    restoreFormState();
    restoreFormCompletedState();

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
        // Manejar si se selecciona como favorito, si es necesario
      },
      onNextStep: () {
        if (userData.location != null) {
          _nextStep();
        } else {
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
        userData.imagePath = imagePath;
        registrationData.imagePath = imagePath;
        print('Imagen seleccionada y asignada: $imagePath');
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
      onServiceTypesSelected: (List<Expertise> expertises, String? selectedExperienceLevel) {
        setState(() {
          userData.expertises = expertises;
          userData.expLevel = selectedExperienceLevel != null ? [selectedExperienceLevel] : [];
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
        userData.idDocumentImagePath = idDocumentImagePath;
        registrationData.idDocumentImagePath = idDocumentImagePath;
        print('Imagen seleccionada y asignada: $idDocumentImagePath');
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
        userData.idDocumentImagePath2 = idDocumentImagePath2;
        registrationData.idDocumentImagePath = idDocumentImagePath2;
        print('Imagen seleccionada y asignada: $idDocumentImagePath2');
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
        userData.criminalRecordImagePath = criminalRecordImagePath;
        registrationData.idDocumentImagePath = criminalRecordImagePath;
        print('Imagen seleccionada y asignada: $criminalRecordImagePath');
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
        userData.certificateImagePaths = certificateImagePaths;
        registrationData.certificateImagePaths = certificateImagePaths;
        print('Imagen seleccionada y asignada: $certificateImagePaths');
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
    if (currentStep == 2 && userData.imagePath.isEmpty) {
      print('Selecciona una imagen antes de pasar al siguiente paso.');
      return;
    }

    if (currentStep == 3 && (userData.expertises.isEmpty || userData.expLevel.isEmpty)) {
      print('Selecciona un tipo de servicio y un nivel de experiencia antes de pasar al siguiente paso.');
      return;
    }

    if (currentStep == 4 && userData.idDocumentImagePath.isEmpty) {
      print('Selecciona una imagen del documento de identidad antes de pasar al siguiente paso.');
      return;
    }

    if (currentStep == 5 && userData.idDocumentImagePath2.isEmpty) {
      print('Selecciona una segunda imagen del documento de identidad antes de pasar al siguiente paso.');
      return;
    }

    setState(() {
      if (currentStep < 7) {
        currentStep += 1;
      }
    });
  }

  Future<String?> _uploadImage(File imageFile, String userId, String imageType) async {
    try {
      final apiService = ApiService();
      User? user = FirebaseAuth.instance.currentUser;
      if (imageFile.existsSync()) {
        final compressedFile = await compressAndResizeImage(imageFile);
        String imageUrl;
        switch (imageType) {
          case 'profile':
            imageUrl = await apiService.uploadImageToFirebaseStorage(compressedFile, userId);
            break;
          case 'idDocument1':
            imageUrl = await apiService.uploadImageToFirebaseStorage2(compressedFile, userId);
            break;
          case 'idDocument2':
            imageUrl = await apiService.uploadImageToFirebaseStorage3(compressedFile, userId);
            break;
          case 'criminalRecord':
            imageUrl = await apiService.uploadImageToFirebaseStorage4(compressedFile, userId);
            break;
          case 'certificate':
            imageUrl = (await apiService.uploadImageToFirebaseStorage5([compressedFile], userId)) as String;
            break;
          default:
            return null;
        }
        print('URL de la imagen cargada ($imageType): $imageUrl');
        return imageUrl;
      } else {
        print('Advertencia: La imagen no existe en la ruta proporcionada para $imageType.');
        return null;
      }
    } catch (e) {
      print('Error al cargar la imagen ($imageType): $e');
      return null;
    }
  }

  Future<File> compressAndResizeImage(File image) async {
    final originalImage = img.decodeImage(image.readAsBytesSync());
    final resizedImage = img.copyResize(originalImage!, width: 600);
    final compressedImage = img.encodeJpg(resizedImage, quality: 50);
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    compressedFile.writeAsBytesSync(compressedImage);
    return compressedFile;
  }

  Future<void> _completeRegistration() async {
    setState(() {
      loadingCompleteRegistration = true;
    });

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
        registrationData.phoneNumber = userData.phoneNumber;

        if (registrationData.imagePath.isNotEmpty) {
          File image = File(registrationData.imagePath);
          if (image.existsSync()) {
            try {
              final compressedFile = await compressAndResizeImage(image);
              final String imageUrl = await apiService.uploadImageToFirebaseStorage(compressedFile, user.uid);
              registrationData.imagePath = imageUrl.endsWith('/') ? imageUrl.substring(0, imageUrl.length - 1) : imageUrl;
              print('URL de la imagen de perfil: ${registrationData.imagePath}');
            } catch (e) {
              print('Error al cargar la imagen de perfil: $e');
            }
          } else {
            print('Advertencia: La imagen de perfil no existe en la ruta proporcionada.');
          }
        } else {
          print('Advertencia: No se proporcionó ninguna imagen de perfil.');
        }

        if (registrationData.idDocumentImagePath.isNotEmpty) {
          File idDocImage = File(registrationData.idDocumentImagePath);
          if (idDocImage.existsSync()) {
            try {
              final compressedFile = await compressAndResizeImage(idDocImage);
              final String idDocImageUrl = await apiService.uploadImageToFirebaseStorage(compressedFile, user.uid);
              registrationData.idDocumentImagePath = idDocImageUrl;
              print('URL de la primera imagen de documento de identificación: $idDocImageUrl');
            } catch (e) {
              print('Error al cargar la primera imagen de documento de identificación: $e');
            }
          } else {
            print('Advertencia: La primera imagen de documento no existe en la ruta proporcionada.');
          }
        } else {
          print('Advertencia: No se proporcionó ninguna imagen de documento de identificación.');
        }

        if (registrationData.idDocumentImagePath2.isNotEmpty) {
          File idDocImage2 = File(registrationData.idDocumentImagePath2);
          if (idDocImage2.existsSync()) {
            try {
              final compressedFile = await compressAndResizeImage(idDocImage2);
              final String idDocImageUrl2 = await apiService.uploadImageToFirebaseStorage(compressedFile, user.uid);
              registrationData.idDocumentImagePath2 = idDocImageUrl2;
              print('URL de la segunda imagen de documento de identificación: $idDocImageUrl2');
            } catch (e) {
              print('Error al cargar la segunda imagen de documento de identificación: $e');
            }
          } else {
            print('Advertencia: La segunda imagen de documento no existe en la ruta proporcionada.');
          }
        } else {
          print('Advertencia: No se proporcionó la segunda imagen de documento de identificación.');
        }

        if (registrationData.certificateImagePaths.isNotEmpty) {
          File certImage = File(registrationData.certificateImagePaths);
          if (certImage.existsSync()) {
            try {
              final compressedFile = await compressAndResizeImage(certImage);
              final String certImageUrl = await apiService.uploadImageToFirebaseStorage(compressedFile, user.uid);
              registrationData.certificateImagePaths = certImageUrl;
              print('URL de la imagen de certificado: $certImageUrl');
            } catch (e) {
              print('Error al cargar la imagen de certificado: $e');
            }
          } else {
            print('Advertencia: La imagen de certificado no existe en la ruta proporcionada.');
          }
        } else {
          print('Advertencia: No se proporcionó ninguna imagen de certificado.');
        }

        if (registrationData.criminalRecordImagePath.isNotEmpty) {
          File crimRecordImage = File(registrationData.criminalRecordImagePath);
          if (crimRecordImage.existsSync()) {
            try {
              final compressedFile = await compressAndResizeImage(crimRecordImage);
              final String crimRecordImageUrl = await apiService.uploadImageToFirebaseStorage(compressedFile, user.uid);
              registrationData.criminalRecordImagePath = crimRecordImageUrl;
              print('URL de la imagen de antecedentes penales: $crimRecordImageUrl');
            } catch (e) {
              print('Error al cargar la imagen de antecedentes penales: $e');
            }
          } else {
            print('Advertencia: La imagen de antecedentes penales no existe en la ruta proporcionada.');
          }
        } else {
          print('Advertencia: No se proporcionó ninguna imagen de antecedentes penales.');
        }

        String? devicesId = await AuthUtils.getDeviceId();
        String? fcmToken = await FirebaseMessaging.instance.getToken();

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
        print('Advertencia: usuario es nulo. Asegúrate de que el usuario esté autenticado correctamente.');
      }
    } catch (error) {
      print('Error durante el proceso de registro: $error');
    } finally {
      setState(() {
        loadingCompleteRegistration = false;
      });
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
      body: Stepper(
        type: StepperType.vertical,
        currentStep: currentStep,
        onStepContinue: () {
          if (currentStep < 7) {
            _nextStep();
          } else {
            _completeRegistration();
          }
        },
        onStepCancel: () {
          if (currentStep > 0) {
            setState(() {
              currentStep -= 1;
            });
          }
        },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (currentStep > 0)
                ElevatedButton(
                  onPressed: details.onStepCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: MyTextStyles.drawerButtonLabelTextStyle,
                  ),
                ),
              ElevatedButton(
                onPressed: details.onStepContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: loadingCompleteRegistration
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text(
                        currentStep == 7 ? 'Completar Registro' : 'Continuar',
                        style: MyTextStyles.drawerButtonLabelTextStyle,
                      ),
              ),
            ],
          );
        },
        steps: <Step>[
          Step(
            title: Text(
              'Datos del Servicio',
              style: MyTextStyles.drawerButtonTextStyle3,
            ),
            content: step1Data,
            isActive: currentStep >= 0,
            state: currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text(
              'Ubicación',
              style: MyTextStyles.drawerButtonTextStyle3,
            ),
            content: step2Location,
            isActive: currentStep >= 1,
            state: currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text(
              'Imagen de Perfil',
              style: MyTextStyles.drawerButtonTextStyle3,
            ),
            content: step3ProfileImage,
            isActive: currentStep >= 2,
            state: currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text(
              'Tipo de Servicio',
              style: MyTextStyles.drawerButtonTextStyle3,
            ),
            content: step4ServiceType,
            isActive: currentStep >= 3,
            state: currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text(
              'Documento de Identidad',
              style: MyTextStyles.drawerButtonTextStyle3,
            ),
            content: step5IdCardImage,
            isActive: currentStep >= 4,
            state: currentStep > 4 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text(
              'Segunda Imagen del Documento',
              style: MyTextStyles.drawerButtonTextStyle3,
            ),
            content: step5IdCardImageB,
            isActive: currentStep >= 5,
            state: currentStep > 5 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text(
              'Antecedentes Penales',
              style: MyTextStyles.drawerButtonTextStyle3,
            ),
            content: step7CriminalRecordImage,
            isActive: currentStep >= 6,
            state: currentStep > 6 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text(
              'Certificados',
              style: MyTextStyles.drawerButtonTextStyle3,
            ),
            content: step8CertificateImage,
            isActive: currentStep >= 7,
            state: currentStep > 7 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }
}
