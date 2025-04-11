import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:image/image.dart' as img;
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/Screens/Home.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentDisplayName = currentUser?.displayName ?? '';

    restoreFormState();
    restoreFormCompletedState();

    setState(() {
      registrationData = RegistrationData(
        userId: '',
        displayName: currentDisplayName,
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
        fcmToken: '', referralCode: '', points: 0, codeReferral: '', verificationStatus: '',
      );

      userData = UserData(
        userId: '',
        displayName: currentDisplayName,
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
        getToken: '', referrerWorkerId: '', referralCode: '', points: 0, verificationStatus: '',
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
      onServiceTypesSelected:
          (List<Expertise> expertises, String? selectedExperienceLevel) {
        setState(() {
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
        registrationData.criminalRecordImagePath = criminalRecordImagePath;
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

    if (currentStep == 3 &&
        (userData.expertises.isEmpty || userData.expLevel.isEmpty)) {
      print(
          'Selecciona un tipo de servicio y un nivel de experiencia antes de pasar al siguiente paso.');
      return;
    }

    if (currentStep == 4 && userData.idDocumentImagePath.isEmpty) {
      print(
          'Selecciona una imagen del documento de identidad antes de pasar al siguiente paso.');
      return;
    }

    if (currentStep == 5 && userData.idDocumentImagePath2.isEmpty) {
      print(
          'Selecciona una segunda imagen del documento de identidad antes de pasar al siguiente paso.');
      return;
    }

    setState(() {
      if (currentStep < 7) {
        currentStep += 1;
      }
    });
  }


  Future<File> compressAndResizeImage(File image) async {
    final originalImage = img.decodeImage(image.readAsBytesSync());
    final resizedImage = img.copyResize(originalImage!, width: 600);
    final compressedImage = img.encodeJpg(resizedImage, quality: 50);
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File(
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    compressedFile.writeAsBytesSync(compressedImage);
    return compressedFile;
  }
  // 2. Función para registrar el referido en la colección "referrals"
  Future<void> _registerReferralInFirestore(String userId, String referralCode) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || referralCode.isEmpty) return;

      final workersRef = FirebaseFirestore.instance.collection('workers');
      final query = await workersRef
          .where('codeReferral', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return;

      final referrer = query.docs.first;
      final referrerId = referrer.id;

      // 1. Crear documento en referrals
      await FirebaseFirestore.instance.collection('referrals').add({
        'referrerId': referrerId,
        'referredUserId': user.uid,
        'referrerCodeReferral': referralCode,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Actualización atómica con transacción
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(referrer.reference);
        final currentData = doc.data()!;

        transaction.update(referrer.reference, {
          'successfulReferrals': currentData['successfulReferrals'] + 1,
          'points': currentData['points'] + 10
        });
      });

    } catch (e) {
      print('Error: $e');
    }
  }


  Future<void> _completeRegistration() async {
    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Espere por favor, estamos registrando en el sistema',
                  style: MyTextStyles.drawerButtonTextStyle3,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

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
        registrationData.referralCode = userData.referrerWorkerId; // Asegúrate de incluir el referralCode

        // Función para subir un archivo y actualizar la URL en registrationData
        Future<void> uploadAndUpdatePath(
            String currentPath,
            Future<String> Function(File, String) uploadFunction,
            String Function(String) setUrlFunction) async {
          if (currentPath.isNotEmpty) {
            File file = File(currentPath);
            if (file.existsSync()) {
              try {
                final compressedFile = await compressAndResizeImage(file);
                final String fileUrl =
                await uploadFunction(compressedFile, user.uid);
                if (fileUrl.isNotEmpty) {
                  setUrlFunction(fileUrl);
                  print('URL del archivo: $fileUrl');
                } else {
                  print('Advertencia: La URL del archivo está vacía.');
                }
              } catch (e) {
                print('Error al cargar el archivo: $e');
              }
            } else {
              print(
                  'Advertencia: El archivo no existe en la ruta proporcionada.');
            }
          } else {
            print('Advertencia: No se proporcionó ningún archivo.');
          }
        }

        // Subir y actualizar cada archivo
        await uploadAndUpdatePath(
            registrationData.imagePath,
            apiService.uploadImageToFirebaseStorage,
                (url) => registrationData.imagePath = url);
        await uploadAndUpdatePath(
            registrationData.idDocumentImagePath,
            apiService.uploadImageToFirebaseStorage2,
                (url) => registrationData.idDocumentImagePath = url);
        await uploadAndUpdatePath(
            registrationData.idDocumentImagePath2,
            apiService.uploadImageToFirebaseStorage3,
                (url) => registrationData.idDocumentImagePath2 = url);
        await uploadAndUpdatePath(
            registrationData.certificateImagePaths,
            apiService.uploadImageToFirebaseStorage4,
                (url) => registrationData.certificateImagePaths = url);

        // Subir el PDF del criminal record
        if (registrationData.criminalRecordImagePath.isNotEmpty) {
          File crimRecordFile = File(registrationData.criminalRecordImagePath);
          if (crimRecordFile.existsSync()) {
            try {
              final String crimRecordUrl = await apiService
                  .uploadImageToFirebaseStorage5(crimRecordFile, user.uid);
              if (crimRecordUrl.isNotEmpty) {
                registrationData.criminalRecordImagePath = crimRecordUrl;
                print('URL del PDF de antecedentes penales: $crimRecordUrl');
              } else {
                print(
                    'Advertencia: La URL del PDF de antecedentes penales está vacía.');
              }
            } catch (e) {
              print('Error al cargar el PDF de antecedentes penales: $e');
            }
          } else {
            print(
                'Advertencia: El PDF de antecedentes penales no existe en la ruta proporcionada.');
          }
        } else {
          print(
              'Advertencia: No se proporcionó ningún PDF de antecedentes penales.');
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
          referralCode: userData.referralCode,
          points: 0,
          codeReferral: registrationData.codeReferral, verificationStatus: registrationData.verificationStatus,
        );

        print('Después de RegistrationData.fromForm:');
        String? token = await user.getIdToken();

        // Registrar el referido si hay un código válido
        if (userData.referralCode.isNotEmpty && userData.referrerWorkerId.isNotEmpty) {
          await _registerReferralInFirestore(user.uid, userData.referralCode);
        }

        // Obtener los puntos actualizados del trabajador
        final userDoc = await FirebaseFirestore.instance.collection('workers').doc(user.uid).get();
        final points = userDoc.data()?['points'] ?? 0;
        registrationData.points = points; // Asignar los puntos al registrationData

        final response = await apiService.updateUser(
          user.uid,
          registrationData,
          token!,
        );

        widget.completeRegistrationCallback();

        // Cerrar el diálogo de carga antes de navegar
        Navigator.of(context).pop();

        if (response.statusCode == 200) {
          print('Usuario actualizado con éxito');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userData: userData,
                registrationData: registrationData,
              ),
            ),
          );
        } else {
          print('Error en la respuesta del servidor: ${response.statusCode}');
          // Mostrar error al usuario
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
              Text('Error al registrar usuario. Intente nuevamente.')));
        }
      } else {
        // Cerrar el diálogo de carga si el usuario es nulo
        Navigator.of(context).pop();
        print(
            'Advertencia: usuario es nulo. Asegúrate de que el usuario esté autenticado correctamente.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error de autenticación. Intente nuevamente.')));
      }
    } catch (error) {
      // Cerrar el diálogo de carga en caso de error
      Navigator.of(context).pop();
      print('Error durante el proceso de registro: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
          Text('Error en el proceso de registro. Intente nuevamente.')));
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
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Registro de Usuario',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(primary: Color(0xFF830A09)),
        ),
        child: Stepper(
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
                      backgroundColor: const Color(0xFF830A09),
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
                    backgroundColor: const Color(0xFF830A09),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: loadingCompleteRegistration
                      ? CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
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
          stepIconBuilder: (int stepIndex, StepState state) {
            return CircleAvatar(
              backgroundColor: Color(0xFF830A09),
              child: Text(
                '${stepIndex + 1}',
                style: MyTextStyles.tabTextStyle1,
              ),
            );
          },
        ),
      ),
    );
  }
}