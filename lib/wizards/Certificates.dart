import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera/camera.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';
import 'dart:io';

import '../Metods/RegisController.dart';

import 'package:flutter/cupertino.dart';

class Step8FormData {
  final List<String> certificateImagePaths;

  Step8FormData({required this.certificateImagePaths});
}

class CertificateImageStep extends StatefulWidget {
  final RegistrationController registrationController;
  final VoidCallback onNextStep;
  final RegistrationData registrationData;
  final void Function(List<String>) onImagesSelected;
  final UserData userData;

  CertificateImageStep({
    required this.registrationController,
    required this.onNextStep,
    required this.registrationData,
    required this.onImagesSelected,
    required this.userData,
  });

  @override
  _CertificateImageStepState createState() => _CertificateImageStepState();
}

class _CertificateImageStepState extends State<CertificateImageStep> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  List<XFile> capturedImages = [];
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
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Paso 8: Cargue una foto de su título o certificado de acreditación laboral(Opcional)",
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
        TextButton(
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
        if (capturedImages.isNotEmpty)
          TextButton(
            onPressed: _isCameraReady && !_isCapturing
                ? _showDeleteImageConfirmation
                : null,
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
              "Eliminar Imagen Seleccionada",
              style: TextStyle(
                color: Color(0xFF84090D),
              ),
            ),
          ),
        if (capturedImages.isNotEmpty)
          Container(
            height: 100.0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: capturedImages.map((image) {
                  return Container(
                    width: (screenWidth - 32) / 3,
                    margin: EdgeInsets.only(right: 8.0),
                    child: Image.file(
                      File(image.path),
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _captureAndShowImage() async {
    try {
      if (_isCapturing) return;

      setState(() {
        _isCapturing = true;
      });

      final XFile image = await _cameraController.takePicture();
      print("Foto capturada de certificates en: ${image.path}");

      setState(() {
        capturedImages.add(image);
      });

      // Actualiza el método onImagesSelected con la lista de rutas de imágenes
      widget
          .onImagesSelected(capturedImages.map((image) => image.path).toList());

      widget.registrationController.updateRegistrationData(
        certificateImagePaths:
            capturedImages.map((image) => image.path).toList(),
        workerType: widget.registrationController.registrationData.paymentType,
        idDocumentImagePath2:
            widget.registrationController.registrationData.idDocumentImagePath2,
        idDocumentImagePath:
            widget.registrationController.registrationData.idDocumentImagePath,
      );
    } catch (e) {
      print("Error al tomar la foto: $e");
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _showDeleteImageConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Eliminar Última Imagen Capturada"),
          content: Text("¿Desea eliminar la última imagen capturada?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  capturedImages.removeLast();
                });
                widget.onImagesSelected(
                    capturedImages.map((image) => image.path).toList());
                Navigator.of(dialogContext).pop();
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
