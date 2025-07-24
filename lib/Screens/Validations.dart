import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:image/image.dart' as img;

import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:socio/wizards/Location.dart';
import 'package:socio/wizards/ProfileImage.dart';

import '../ServiceResponse/get.dart';
import '../ServiceResponse/post.dart';
import '../ServiceResponse/requestExpertise.dart';
import '../ServiceResponse/requestUserData.dart';
import '../Utils/styles.dart';
import '../controllers/RegisController.dart';
import '../provider/providerImage.dart';
import '../provider/providerRegistration.dart';
import '../wizards/Certificates.dart';
import '../wizards/CriminalRecords.dart';
import '../wizards/DocumentB.dart';
import '../wizards/IdDocument.dart';
import '../wizards/ServiceTypeSelection.dart';
import '../wizards/forms.dart';
import '../wizards/licenseMedical.dart';
import '../wizards/profesionalTittle.dart';

class RegistrationScreen extends StatelessWidget {
  final RegistrationController registrationController;
  final VoidCallback completeRegistrationCallback;
  final ApiService apiService;
  final ApiService2 apiService2;
  final UserData userData;

  RegistrationScreen({
    required this.registrationController,
    required this.completeRegistrationCallback,
    required this.apiService,
    required this.apiService2,
    required this.userData,
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
          final steps = <Widget>[
            ServiceDataWizard(
              onNextStep: provider.nextStep,
              userData: provider.userData,
            ),
            LocationAndFavoritesWizard(
              onLocationSelected: provider.setLocation,
              onFavoritesSelected: (fav) {
                provider.registrationData.isFavorite = fav;
                provider.notifyListeners();
              },
              onNextStep: provider.nextStep,
              location: provider.registrationData.location
                      ?.map((k, v) => MapEntry(k, v ?? 0.0)) ??
                  {'latitude': 0.0, 'longitude': 0.0},
            ),
            ProfileImage(
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
            ServiceTypeSelection(
              registrationController: provider.registrationController,
              onNextStep: provider.nextStep,
              onServiceTypeSelected: (_) {},
              fetchExpertises: apiService2.fetchExpertises,
              onServiceTypesSelected: (List<Expertise> expertises,
                  String? selectedExperienceLevel) {
                provider.userData.expertises = expertises;
                provider.userData.expLevel = selectedExperienceLevel != null
                    ? [selectedExperienceLevel]
                    : [];
                provider.registrationData.expertises = expertises;
                provider.registrationData.expLevel =
                    selectedExperienceLevel != null
                        ? [selectedExperienceLevel]
                        : [];
                provider.notifyListeners();
              },
            ),
            IdCardImageStep(
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
            IdCardImageStepB(
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
            CriminalRecordImageStep(
              registrationController: provider.registrationController,
              onImageSelected: (path) {
                provider.userData.criminalRecordImagePath = path;
                provider.registrationData.criminalRecordImagePath = path;
                provider.notifyListeners();
              },
              criminalRecordImagePath:
                  provider.userData.criminalRecordImagePath,
              registrationData: provider.registrationData,
              userData: provider.userData,
              isImageCaptured: ValueNotifier(
                  provider.userData.criminalRecordImagePath.isNotEmpty),
              onNextStep: provider.nextStep,
            ),
            CertificateImageStep(
              registrationController: provider.registrationController,
              onImageSelected: (List<String> paths) {
                provider.userData.certificateImagePaths = paths;
                provider.registrationData.certificateImagePaths = paths;
                provider.notifyListeners();
              },
              certificateImagePaths: provider.userData.certificateImagePaths,
              registrationData: provider.registrationData,
              userData: provider.userData,
              isImageCaptured: ValueNotifier(
                  provider.userData.certificateImagePaths.isNotEmpty),
              onNextStep: provider.nextStep,
            ),
          ];

          final stepTitles = [
            'Datos del Servicio',
            'Ubicación',
            'Imagen de Perfil',
            'Tipo de Servicio',
            'Documento de Identidad',
            'Segunda Imagen del Documento',
            'Antecedentes Penales',
            'Certificados',
          ];

          return Scaffold(
            appBar: AppBar(
              iconTheme: IconThemeData(color: Colors.white),
              title: Text('Registro de Usuario',
                  style: MyTextStyles.buttonTextStyle),
              backgroundColor: const Color(0xFF830A09),
            ),
            body: Column(
              children: [
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: List.generate(steps.length, (idx) {
                      final isActive = idx == provider.currentStep;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          height: isActive ? 16 : 10,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF830A09)
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    stepTitles[provider.currentStep],
                    style: MyTextStyles.drawerButtonTextStyle3
                        .copyWith(fontSize: 20),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    child: Card(
                      key: ValueKey(provider.currentStep),
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: steps[provider.currentStep],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (provider.currentStep > 0)
                        ElevatedButton.icon(
                          onPressed: provider.previousStep,
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          label: Text('Anterior',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF830A09),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: provider.loading
                            ? null
                            : () {
                                if (provider.currentStep < steps.length - 1) {
                                  provider.nextStep();
                                } else {
                                  provider.completeRegistration(context);
                                }
                              },
                        icon: provider.currentStep == steps.length - 1
                            ? Icon(Icons.check, color: Colors.white)
                            : Icon(Icons.arrow_forward, color: Colors.white),
                        label: provider.loading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                provider.currentStep == steps.length - 1
                                    ? 'Completar'
                                    : 'Siguiente',
                                style: TextStyle(color: Colors.white),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF830A09),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
