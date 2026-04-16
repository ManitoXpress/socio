import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socio/controllers/RegisController.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/wizards/DocsAndCertificates.dart';
import 'package:socio/wizards/IdDocumentCombined.dart';
import 'package:socio/wizards/Location.dart';
import 'package:socio/wizards/ProfileImage.dart';
import 'package:socio/wizards/ServiceTypeSelection.dart';
import 'package:socio/wizards/forms.dart';
import 'package:provider/provider.dart';

import '../provider/providerImage.dart';
import '../provider/providerRegistration.dart';

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
          // === PASOS REDUCIDOS: 8 → 6 (fusionamos carnet frente+reverso) ===
          final steps = <Widget>[
            // PASO 1: Datos personales
            ServiceDataWizard(
              onNextStep: provider.nextStep,
            ),
            // PASO 2: Ubicación
            LocationAndFavoritesWizard(
              onLocationSelected: provider.setLocation,
              onFavoritesSelected: (fav) {
                provider.registrationData.isFavorite = fav;
                provider.notifyListeners();
              },
              onCitySelected: (city, region) {
                provider.registrationData.city = city;
                provider.registrationData.region = region;
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
            // PASO 3: Foto de perfil
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
            // PASO 4: Tipo de servicio
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
            // PASO 5: Documento de identidad (frente + reverso combinados)
            IdDocumentCombinedStep(
              registrationController: provider.registrationController,
              onImagesSelected: (front, back) {
                provider.userData.idDocumentImagePath = front;
                provider.registrationData.idDocumentImagePath = front;
                provider.userData.idDocumentImagePath2 = back;
                provider.registrationData.idDocumentImagePath2 = back;
                provider.notifyListeners();
              },
              idDocumentImagePath: provider.userData.idDocumentImagePath,
              idDocumentImagePath2: provider.userData.idDocumentImagePath2,
              registrationData: provider.registrationData,
              userData: provider.userData,
              isImageCaptured: ValueNotifier(
                  provider.userData.idDocumentImagePath.isNotEmpty &&
                      provider.userData.idDocumentImagePath2.isNotEmpty),
              onNextStep: provider.nextStep,
            ),
            // PASO 6: Antecedentes + Certificados + Título (combinados)
            DocsAndCertificatesStep(
              registrationController: provider.registrationController,
              onCriminalSelected: (path) {
                provider.userData.criminalRecordImagePath = path;
                provider.registrationData.criminalRecordImagePath = path;
                provider.notifyListeners();
              },
              onCertificatesSelected: (paths) {
                provider.userData.certificateImagePaths = paths;
                provider.registrationData.certificateImagePaths = paths;
                provider.notifyListeners();
              },
              criminalRecordImagePath:
                  provider.userData.criminalRecordImagePath,
              certificateImagePaths: provider.userData.certificateImagePaths,
              registrationData: provider.registrationData,
              userData: provider.userData,
              isImageCaptured: ValueNotifier(
                  provider.userData.criminalRecordImagePath.isNotEmpty),
              onNextStep: provider.nextStep,
            ),
          ];

          final stepMeta = [
            _StepMeta(icon: Icons.person_outline, label: 'Datos'),
            _StepMeta(icon: Icons.location_on_outlined, label: 'Ubicación'),
            _StepMeta(icon: Icons.face_outlined, label: 'Foto'),
            _StepMeta(icon: Icons.work_outline, label: 'Servicio'),
            _StepMeta(icon: Icons.credit_card_outlined, label: 'Carnet'),
            _StepMeta(icon: Icons.verified_outlined, label: 'Documentos'),
          ];

          final currentStep = provider.currentStep;
          final totalSteps = steps.length;

          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F9),
            appBar: _buildAppBar(context, currentStep, totalSteps),
            body: Column(
              children: [
                // === STEPPER PREMIUM ===
                _buildStepper(stepMeta, currentStep),

                // === TÍTULO DEL PASO ===
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF830A09).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Paso ${currentStep + 1} de $totalSteps',
                          style: const TextStyle(
                            color: Color(0xFF830A09),
                            fontFamily: 'Xpress',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        stepMeta[currentStep].label,
                        style: const TextStyle(
                          fontFamily: 'Xpress',
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          fontSize: 18,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // === CONTENIDO DEL PASO ===
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey(currentStep),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: steps[currentStep],
                        ),
                      ),
                    ),
                  ),
                ),

                // === BOTONES DE NAVEGACIÓN ===
                _buildNavButtons(context, provider, currentStep, totalSteps),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, int currentStep, int totalSteps) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF830A09),
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        'Registro de Usuario',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Xpress',
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          fontSize: 18,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 4,
          child: LinearProgressIndicator(
            value: (currentStep + 1) / totalSteps,
            backgroundColor: Colors.white.withOpacity(0.25),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper(List<_StepMeta> stepMeta, int currentStep) {
    return Container(
      color: const Color(0xFF830A09),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(stepMeta.length, (i) {
          final isCompleted = i < currentStep;
          final isActive = i == currentStep;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Línea izquierda + icono + línea derecha
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 2,
                          color: isCompleted || isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: isActive ? 36 : 28,
                      height: isActive ? 36 : 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.white
                            : isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check,
                                size: 14, color: const Color(0xFF830A09))
                            : Icon(
                                stepMeta[i].icon,
                                size: isActive ? 18 : 13,
                                color: isActive
                                    ? const Color(0xFF830A09)
                                    : Colors.white.withOpacity(0.6),
                              ),
                      ),
                    ),
                    if (i < stepMeta.length - 1)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 2,
                          color: isCompleted
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavButtons(BuildContext context, RegistrationProvider provider,
      int currentStep, int totalSteps) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Botón Anterior
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: provider.previousStep,
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Color(0xFF830A09), size: 18),
                  label: const Text(
                    'Anterior',
                    style: TextStyle(
                      color: Color(0xFF830A09),
                      fontFamily: 'Xpress',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF830A09), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 12),
            // Botón Siguiente / Completar
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: provider.loading
                    ? null
                    : () {
                        if (currentStep < totalSteps - 1) {
                          provider.nextStep();
                        } else {
                          provider.completeRegistration(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF830A09),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: provider.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentStep == totalSteps - 1
                                ? 'Completar'
                                : 'Siguiente',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Xpress',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            currentStep == totalSteps - 1
                                ? Icons.check_circle_outline
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
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

class _StepMeta {
  final IconData icon;
  final String label;
  const _StepMeta({required this.icon, required this.label});
}