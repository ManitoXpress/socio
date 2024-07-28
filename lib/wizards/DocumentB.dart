import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera/camera.dart';
import 'dart:io';

import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';

class Step6FormData {
  final String idDocumentImagePath2;

  Step6FormData({required this.idDocumentImagePath2});
}

class IdCardImageStepB extends StatefulWidget {
  final Function(Step6FormData) onImageSelected;
  final RegistrationController registrationController;
  final void Function() onNextStep;
  late _IdCardImageStepBState _idCardImageStepBState;
  bool isStep6Valid() {
    return _idCardImageStepBState.isStep6Valid();
  }

  IdCardImageStepB({
    required this.registrationController,
    required this.onImageSelected,
    required this.onNextStep,
    required idDocumentImagePath,
    required Null Function(Step6FormData image2) onImageSelected2,
    required UserData userData,
    required RegistrationData registrationData,
    required Step6FormData formData2,
  });

  @override
  _IdCardImageStepBState createState() {
    _idCardImageStepBState = _IdCardImageStepBState();
    return _idCardImageStepBState;
  }
}

class _IdCardImageStepBState extends State<IdCardImageStepB> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? capturedImage;
  int currentStep = 0;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  bool isStep6Valid() {
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
            "Paso 6: Necesitamos una foto del reverso de su carnet",
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
        if (!isStep6Valid())
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
          Step6FormData(idDocumentImagePath2: capturedImage?.path ?? ''));

      widget.registrationController.updateRegistrationData(
        idDocumentImagePath2: capturedImage?.path ?? '',
        workerType: '',
        idDocumentImagePath: '',
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
