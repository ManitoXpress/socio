import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socio/Controller/RegisController.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/provider/providerImage.dart';

import 'package:socio/provider/providerRegistration.dart';
import 'package:socio/wizards/Certificates.dart';
import 'package:socio/wizards/CriminalRecords.dart';
import 'package:socio/wizards/DocumentB.dart';
import 'package:socio/wizards/IdDocument.dart';
import 'package:socio/wizards/Location.dart';
import 'package:socio/wizards/ProfileImage.dart';
import 'package:socio/wizards/ServiceTypeSelection.dart';
import 'package:socio/wizards/forms.dart';

class RegistrationScreen extends StatelessWidget {
  final RegistrationController registrationController;
  final VoidCallback completeRegistrationCallback;
  final ApiService apiService;
  final ApiService2 apiService2;

  RegistrationScreen({
    required this.registrationController,
    required this.completeRegistrationCallback,
    required this.apiService,
    required this.apiService2,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RegistrationProvider(
            registrationController: registrationController,
            completeRegistrationCallback: completeRegistrationCallback,
            apiService: apiService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => ImageStateProvider()),
      ],
      child: Consumer<RegistrationProvider>(
        builder: (context, provider, _) {
          final steps = <Step>[
            Step(
              title: Text('Datos del Servicio', style: MyTextStyles.drawerButtonTextStyle3),
              content: ServiceDataWizard(onNextStep: provider.nextStep),
              isActive: provider.currentStep >= 0,
              state: provider.currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Ubicación', style: MyTextStyles.drawerButtonTextStyle3),
              content: LocationAndFavoritesWizard(
                onLocationSelected: provider.setLocation,
                onFavoritesSelected: (fav) {
                  provider.registrationData.isFavorite = fav;
                  provider.notifyListeners();
                },
                onNextStep: provider.nextStep,
                location: provider.registrationData.location
                    ?.map((k, v) => MapEntry(k, v ?? 0.0)) ??
                    {'latitude': 0.0, 'longitude': 0.0},
                registrationController: provider.registrationController,
                userData: provider.userData,
                registrationData: provider.registrationData,
              ),
              isActive: provider.currentStep >= 1,
              state: provider.currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Imagen de Perfil', style: MyTextStyles.drawerButtonTextStyle3),
              content: ProfileImage(
                registrationController: provider.registrationController,
                onImageSelected: (path) {
                  provider.userData.imagePath = path;
                  provider.registrationData.imagePath = path;
                  provider.notifyListeners();
                },
                imagePath: provider.userData.imagePath,
                registrationData: provider.registrationData,
                userData: provider.userData,
                isImageCaptured:
                ValueNotifier(provider.userData.imagePath.isNotEmpty),
                onNextStep: provider.nextStep,
              ),
              isActive: provider.currentStep >= 2,
              state: provider.currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Tipo de Servicio', style: MyTextStyles.drawerButtonTextStyle3),
              content: ServiceTypeSelection(
                registrationController: provider.registrationController,
                onNextStep: provider.nextStep,
                onServiceTypeSelected: (_) {},
                fetchExpertises: apiService2.fetchExpertises,
                onServiceTypesSelected:
                    (List<Expertise> expertises, String? selectedExperienceLevel) {
                  provider.userData.expertises = expertises;
                  provider.userData.expLevel =
                  selectedExperienceLevel != null ? [selectedExperienceLevel] : [];
                  provider.registrationData.expertises = expertises;
                  provider.registrationData.expLevel =
                  selectedExperienceLevel != null ? [selectedExperienceLevel] : [];
                  provider.notifyListeners();
                },
              ),
              isActive: provider.currentStep >= 3,
              state: provider.currentStep > 3 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Documento de Identidad', style: MyTextStyles.drawerButtonTextStyle3),
              content: IdCardImageStep(
                registrationController: provider.registrationController,
                onImageSelected: (path) {
                  provider.userData.idDocumentImagePath = path;
                  provider.registrationData.idDocumentImagePath = path;
                  provider.notifyListeners();
                },
                idDocumentImagePath: provider.userData.idDocumentImagePath,
                registrationData: provider.registrationData,
                userData: provider.userData,
                isImageCaptured: ValueNotifier(
                    provider.userData.idDocumentImagePath.isNotEmpty),
                onNextStep: provider.nextStep,
              ),
              isActive: provider.currentStep >= 4,
              state: provider.currentStep > 4 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Segunda Imagen del Documento', style: MyTextStyles.drawerButtonTextStyle3),
              content: IdCardImageStepB(
                registrationController: provider.registrationController,
                onImageSelected: (path) {
                  provider.userData.idDocumentImagePath2 = path;
                  provider.registrationData.idDocumentImagePath2 = path;
                  provider.notifyListeners();
                },
                idDocumentImagePath2: provider.userData.idDocumentImagePath2,
                registrationData: provider.registrationData,
                userData: provider.userData,
                isImageCaptured: ValueNotifier(
                    provider.userData.idDocumentImagePath2.isNotEmpty),
                onNextStep: provider.nextStep,
              ),
              isActive: provider.currentStep >= 5,
              state: provider.currentStep > 5 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Antecedentes Penales', style: MyTextStyles.drawerButtonTextStyle3),
              content: CriminalRecordImageStep(
                registrationController: provider.registrationController,
                onImageSelected: (path) {
                  provider.userData.criminalRecordImagePath = path;
                  provider.registrationData.criminalRecordImagePath = path;
                  provider.notifyListeners();
                },
                criminalRecordImagePath: provider.userData.criminalRecordImagePath,
                registrationData: provider.registrationData,
                userData: provider.userData,
                isImageCaptured: ValueNotifier(
                    provider.userData.criminalRecordImagePath.isNotEmpty),
                onNextStep: provider.nextStep,
              ),
              isActive: provider.currentStep >= 6,
              state: provider.currentStep > 6 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Certificados', style: MyTextStyles.drawerButtonTextStyle3),
              content: CertificateImageStep(
                registrationController: provider.registrationController,
                onImageSelected: (path) {
                  provider.userData.certificateImagePaths = path;
                  provider.registrationData.certificateImagePaths = path;
                  provider.notifyListeners();
                },
                certificateImagePaths: provider.userData.certificateImagePaths,
                registrationData: provider.registrationData,
                userData: provider.userData,
                isImageCaptured:
                ValueNotifier(provider.userData.certificateImagePaths.isNotEmpty),
                onNextStep: provider.nextStep,
              ),
              isActive: provider.currentStep >= 7,
              state: provider.currentStep > 7 ? StepState.complete : StepState.indexed,
            ),
          ];

          return Scaffold(
            appBar: AppBar(
              iconTheme: IconThemeData(color: Colors.white),
              title: Text('Registro de Usuario', style: MyTextStyles.buttonTextStyle),
              backgroundColor: const Color(0xFF830A09),
            ),
            body: Theme(
              data: ThemeData(
                  colorScheme: ColorScheme.light(primary: const Color(0xFF830A09))),
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints:
                  BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                  child: Stepper(
                    key: ValueKey(steps.length),
                    physics: NeverScrollableScrollPhysics(),
                    type: StepperType.vertical,
                    currentStep: provider.currentStep,
                    onStepContinue: () {
                      if (provider.currentStep < steps.length - 1) {
                        provider.nextStep();
                      } else {
                        // Ahora pasamos 'context' al completar
                        provider.completeRegistration(context);
                      }
                    },
                    onStepCancel: () {
                      if (provider.currentStep > 0) {
                        provider.previousStep();
                      }
                    },
                    controlsBuilder: (context, details) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        if (provider.currentStep > 0)
                          ElevatedButton(
                            onPressed: details.onStepCancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF830A09),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Cancelar',
                                style: MyTextStyles.drawerButtonLabelTextStyle),
                          ),
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF830A09),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          child: provider.loading
                              ? CircularProgressIndicator(
                              valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white))
                              : Text(
                            provider.currentStep == steps.length - 1
                                ? 'Completar Registro'
                                : 'Continuar',
                            style:
                            MyTextStyles.drawerButtonLabelTextStyle,
                          ),
                        ),
                      ],
                    ),
                    stepIconBuilder: (idx, _) => CircleAvatar(
                      backgroundColor: const Color(0xFF830A09),
                      child: Text('${idx + 1}',
                          style: MyTextStyles.tabTextStyle1),
                    ),
                    steps: steps,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}