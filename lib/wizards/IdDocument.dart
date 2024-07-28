import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';

class Step5FormData {
  final String idDocumentImagePath;

  Step5FormData({required this.idDocumentImagePath});
}

class IdCardImageStep extends StatefulWidget {
  final Function(Step5FormData) onImageSelected;
  final RegistrationController registrationController;
  late _IdCardImageStepState _idCardImageStepState;
  final void Function() onNextStep;
  bool isStep5Valid() {
    return _idCardImageStepState.isStep5Valid();
  }

  IdCardImageStep({
    required this.registrationController,
    required this.onImageSelected,
    required this.onNextStep,
    required idDocumentImagePath,
    required Null Function(Step5FormData image2) onImageSelected2,
    required UserData userData,
    required RegistrationData registrationData,
    required Step5FormData formData2,
  });

  @override
  _IdCardImageStepState createState() {
    _idCardImageStepState = _IdCardImageStepState();
    return _idCardImageStepState;
  }
}

class _IdCardImageStepState extends State<IdCardImageStep> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? capturedImage;
  int currentStep = 0;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  bool isStep5Valid() {
    return capturedImage != null;
  }

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
            "Paso 5: Necesitamos una foto de su carnet de la parte frontal",
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
        if (!isStep5Valid())
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Saca una foto antes de dar siguiente paso.',
              style: TextStyle(color: Color(0xFF830A09)),
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
          Step5FormData(idDocumentImagePath: capturedImage?.path ?? ''));

      widget.registrationController.updateRegistrationData(
        idDocumentImagePath: capturedImage?.path ?? '',
        workerType: '',
        idDocumentImagePath2: '',
        certificateImagePaths: [],
      );
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
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar Imagen Capturada"),
          content: Text("¿Desea eliminar la imagen capturada?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  capturedImage = null; // Eliminar la imagen capturada
                });
                Navigator.of(context).pop(); // Cerrar el diálogo
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
