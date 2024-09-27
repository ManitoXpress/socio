import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/Screens/Home.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/wizards/Certificates.dart';
import 'package:socio/wizards/CriminalRecords.dart';
import 'package:socio/wizards/DocumentB.dart';
import 'package:socio/wizards/IdDocument.dart';
import 'package:socio/wizards/Location.dart';
import 'package:socio/wizards/ProfileImage.dart';
import 'package:socio/wizards/ServiceTypeSelection.dart';
import 'package:socio/wizards/forms.dart';

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

  // Bandera para controlar si el formulario ya se completó
  bool formCompleted = false;
  bool loadingCompleteRegistration = false;

  @override
  void initState() {
    super.initState();

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
        certificateImagePaths: [],
        expLevel: [],
        selectedCountryCode: '',
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
        certificateImagePaths: [],
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
      onImageSelected: (Step3FormData image) {
        setState(() {
          userData.imagePath = image.imagePath;
          step3ProfileImage.isImageCaptured.value = true;
        });
      },
      formData: Step3FormData(imagePath: ''),
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
          (List<Expertises> expertises, String? selectedExperienceLevel) {
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
      onImageSelected: (Step5FormData image) {
        setState(() {
          userData.idDocumentImagePath = image.idDocumentImagePath;
        });
      },
      registrationController: registrationController,
      onNextStep: _nextStep,
      formData2: Step5FormData(idDocumentImagePath: ''),
      registrationData: registrationData,
      userData: userData,
      idDocumentImagePath: '',
      onImageSelected2: (Step5FormData image2) {},
    );
    step5IdCardImageB = IdCardImageStepB(
      onImageSelected: (Step6FormData image) {
        setState(() {
          userData.idDocumentImagePath2 = image.idDocumentImagePath2 as String;
        });
      },
      registrationController: registrationController,
      onNextStep: _nextStep,
      formData2: Step6FormData(idDocumentImagePath2: ''),
      registrationData: registrationData,
      userData: userData,
      idDocumentImagePath: '',
      onImageSelected2: (Step6FormData image2) {},
    );

    step7CriminalRecordImage = CriminalRecordImageStep(
      onImageSelected: (Step7FormData image) {
        setState(() {
          userData.criminalRecordImagePath = image.criminalRecordImagePath;
        });
      },
      onNextStep: _nextStep,
      registrationData: registrationData,
      registrationController: registrationController,
      userData: userData,
    );
    step8CertificateImage = CertificateImageStep(
      onNextStep: _nextStep,
      registrationData: registrationData,
      registrationController: registrationController,
      userData: userData,
      onImagesSelected: (List<String> certificateImagePaths) {
        setState(() {
          userData.certificateImagePaths = certificateImagePaths;
        });
      },
    );
  }

  void restoreFormState() {
    // Lógica para cargar datos previos del formulario si es necesario
  }

  void restoreFormCompletedState() {
    // Lógica para cargar el estado de la bandera si es necesario
  }
  void _nextStep() {
    // Validar el primer paso
    if (currentStep == 0) {
      if (!step1Data.isStep1Valid()) {
        print(
            'Completa todos los campos obligatorios antes de pasar al siguiente paso.');
        return;
      }
    }

    // Validar el segundo paso
    if (currentStep == 1 &&
        !(step2Location.isLocationAndFavoritesValid() ?? false)) {
      print(
          'Completa la ubicación y la información adicional antes de pasar al siguiente paso.');
      return;
    }
    // Validar el tercer paso (Step3 - ProfileImage)

    // Validar el quinto paso (Step5 - idDocumentA)

    if (currentStep == 4 && !(step5IdCardImage.isStep5Valid())) {
      print(
          'Completa la ubicación y la información adicional antes de pasar al siguiente paso.');
      return;
    }
    // Validar el sexto paso (Step6 - idDocumentB)

    if (currentStep == 5 && !(step5IdCardImageB.isStep6Valid())) {
      print(
          'Completa la ubicación y la información adicional antes de pasar al siguiente paso.');
      return;
    }

    setState(() {
      if (currentStep < 7) {
        currentStep += 1;
      }
    });
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

      final Step3FormData step3FormData =
          widget.registrationController.step3FormData;
      final Step5FormData step5FormData =
          widget.registrationController.step5FormData;
      final Step6FormData step6FormData =
          widget.registrationController.step6FormData;
      final Step7FormData step7FormData =
          widget.registrationController.step7FormData;
      final Step8FormData step8FormData =
          widget.registrationController.step8FormData;

      // Subir la imagen de perfil
      if (step3FormData.imagePath.isNotEmpty) {
        File imageFile = File(userData.imagePath);

        if (imageFile.existsSync()) {
          registrationData.imagePath = userData.imagePath;
          final String imageUrl = await apiService.uploadImageToFirebaseStorage(
              File(userData.imagePath), user.uid);
          registrationData.imagePath = imageUrl;
          print('URL de la imagen en _uploadProfileImage: $imageUrl');
        } else {
          print('Advertencia: La imagen no existe en la ruta proporcionada.');
        }
      }

      // Subir las imágenes del documento de identificación
      if (step5FormData.idDocumentImagePath.isNotEmpty) {
        File imageFile = File(userData.idDocumentImagePath);

        if (imageFile.existsSync()) {
          final String idDocImageUrl = await apiService.uploadImageToFirebaseStorage2(
              File(userData.idDocumentImagePath), user.uid);
          registrationData.idDocumentImagePath = idDocImageUrl;
          print('URL de la imagen en idDocumentImagePath: $idDocImageUrl');
        } else {
          print('Advertencia: La imagen no existe en la ruta proporcionada.');
        }
      }

      // Subir la segunda imagen del documento de identificación
      if (step6FormData.idDocumentImagePath2.isNotEmpty) {
        File imageFile = File(userData.idDocumentImagePath2);

        if (imageFile.existsSync()) {
          final String idDocImageUrl2 = await apiService.uploadImageToFirebaseStorage3(
              File(userData.idDocumentImagePath2), user.uid);
          registrationData.idDocumentImagePath2 = idDocImageUrl2;
          print('URL de la imagen en idDocumentImagePath2: $idDocImageUrl2');
        } else {
          print('Advertencia: La imagen no existe en la ruta proporcionada.');
        }
      }

      // Subir el archivo de antecedentes penales
      if (step7FormData.criminalRecordImagePath.isNotEmpty) {
        File imageFile = File(userData.criminalRecordImagePath);

        if (imageFile.existsSync()) {
          final String criminalRecordImageUrl = await apiService.uploadImageToFirebaseStorage4(
              File(userData.criminalRecordImagePath), user.uid);
          registrationData.criminalRecordImagePath = criminalRecordImageUrl;
          print('URL de la imagen en criminalRecordImagePath: $criminalRecordImageUrl');
        } else {
          print('Advertencia: La imagen no existe en la ruta proporcionada.');
        }
      }

      // Subir certificados
      if (userData.certificateImagePaths.isNotEmpty) {
        List<String> uploadedCertUrls = [];

        for (String certificatePath in userData.certificateImagePaths) {
          File certFile = File(certificatePath);

          if (certFile.existsSync()) {
            final List<String> certImageUrl = await apiService.uploadImageToFirebaseStorage5(
                certFile as List<File>, user.uid);
            uploadedCertUrls.add(certImageUrl as String);
          } else {
            print('Advertencia: El certificado no existe en la ruta proporcionada.');
          }
        }

        registrationData.certificateImagePaths = uploadedCertUrls;
        print('URLs de las imágenes en certificateImagePaths: $uploadedCertUrls');
      } else {
        print('Advertencia: La lista de rutas de certificateImagePaths está vacía.');
      }

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
              onPressed: () {
                if (currentStep == 7) {
                  setState(() {
                    loadingCompleteRegistration = true;
                  });
                  _completeRegistration().then((_) {
                    setState(() {
                      loadingCompleteRegistration = false;
                    });
                  });
                } else {
                  _nextStep();
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                backgroundColor: Color(0xFF84090D),
                minimumSize: Size(double.infinity, 50),
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
