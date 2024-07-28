import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera/camera.dart';
import 'dart:io';

import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';

class Step7FormData {
  final String criminalRecordImagePath;

  Step7FormData({required this.criminalRecordImagePath});
}

class CriminalRecordImageStep extends StatefulWidget {
  final Function(Step7FormData) onImageSelected;
  final RegistrationController registrationController;
  final VoidCallback onNextStep;
  final RegistrationData registrationData;
  final UserData userData;

  CriminalRecordImageStep({
    required this.onImageSelected,
    required this.registrationController,
    required this.onNextStep,
    required this.registrationData,
    required this.userData,
  });

  @override
  _CriminalRecordImageStepState createState() =>
      _CriminalRecordImageStepState();
}

class _CriminalRecordImageStepState extends State<CriminalRecordImageStep> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? capturedImage;
  bool _isCameraReady = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _cameraController.initialize();

      await _initializeControllerFuture;

      setState(() {
        _isCameraReady = true;
      });

      print("Cámara inicializada correctamente");
    } catch (e) {
      print("Error al inicializar la cámara: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Paso 7: Saque una foto a sus antecedentes penales(Opcional)",
            style: MyTextStyles.formServiceTextStyle,
          ),
        ),
        Container(
          height: 400,
          width: double.maxFinite,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _isCameraReady ? _captureAndShowImage : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: _isCameraReady
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            CameraPreview(_cameraController),
                            if (capturedImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: Image.file(
                                  File(capturedImage!.path),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        )
                      : Center(
                          child: CircularProgressIndicator(),
                        ),
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed:
              _isCameraReady && !_isCapturing ? _captureAndShowImage : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                color: Color(0xFF84090D),
              ),
            ),
          ),
          child: Text(
            "Capturar Imagen",
            style: TextStyle(
              color: Color(0xFF84090D),
            ),
          ),
        ),
        if (capturedImage != null)
          ElevatedButton(
            onPressed:
                _isCameraReady && !_isCapturing ? _captureAndShowImage : null,
            style: TextButton.styleFrom(
              foregroundColor: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(
                  color: Color(0xFF84090D),
                ),
              ),
            ),
            child: Text(
              "Eliminar Imagen Capturada",
              style: TextStyle(
                color: Color(0xFF84090D),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _captureAndShowImage() async {
    try {
      // Bloquear la captura si ya está en progreso
      if (_isCapturing) return;

      // Marcar como captura en progreso
      setState(() {
        _isCapturing = true;
      });

      final XFile image = await _cameraController.takePicture();
      print("Foto capturada en: ${image.path}");

      // Guardar la imagen
      setState(() {
        capturedImage = image;
      });
      widget.onImageSelected(
          Step7FormData(criminalRecordImagePath: capturedImage?.path ?? ''));

      widget.registrationController.updateRegistrationData(
          idDocumentImagePath: capturedImage?.path ?? '',
          workerType: '',
          idDocumentImagePath2: '',
          certificateImagePaths: []);
    } catch (e) {
      print("Error al tomar la foto: $e");
    } finally {
      // Marcar como captura finalizada
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _showDeleteImageConfirmation() {
    showDialog(
      context: context, // Asegúrate de usar el contexto actual
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Eliminar Imagen Capturada"),
          content: Text("¿Desea eliminar la imagen capturada?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cerrar el diálogo
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  capturedImage = null; // Eliminar la imagen capturada
                });
                Navigator.of(dialogContext).pop(); // Cerrar el diálogo
              },
              child: Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}
