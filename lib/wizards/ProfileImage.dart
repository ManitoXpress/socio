import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';

class Step3FormData {
  final String imagePath;

  Step3FormData({required this.imagePath});
}

class ProfileImage extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function(Step3FormData image) onImageSelected;
  final String imagePath;
  final Step3FormData formData;
  final RegistrationData registrationData;
  final UserData userData;
  final ValueNotifier<bool> isImageCaptured;
  final void Function() onNextStep;
  late _ProfileImageState _profileImageState;

  bool isStep3Valid() {
    return _profileImageState.isStep3Valid();
  }

  ProfileImage({
    required this.registrationController,
    required this.onImageSelected,
    required this.imagePath,
    required this.formData,
    required this.registrationData,
    required this.userData,
    required this.isImageCaptured,
    required this.onNextStep,
  });

  @override
  _ProfileImageState createState() {
    _profileImageState = _ProfileImageState();
    return _profileImageState;
  }
}

class _ProfileImageState extends State<ProfileImage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? capturedImage;
  bool _isCameraReady = false;
  bool _isCapturing = false;

  // Función para validar
  bool isStep3Valid() {
    return capturedImage != null;
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _requestCameraPermission().then((_) {
      return _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
      );

      await _cameraController.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }

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
            "Paso 3: Saquese una foto de perfil sin gafas y sin gorra",
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
          onPressed: _isCameraReady && !_isCapturing ? _captureAndShowImage : null,
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
            onPressed: _isCameraReady && !_isCapturing ? _showDeleteImageConfirmation : null,
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
        if (!isStep3Valid())
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
      if (_isCapturing) return;

      setState(() {
        _isCapturing = true;
      });

      final XFile image = await _cameraController.takePicture();
      print("Foto capturada en: ${image.path}");

      if (mounted) {
        setState(() {
          capturedImage = image;
        });

        widget.onImageSelected(Step3FormData(imagePath: capturedImage?.path ?? ''));
        widget.isImageCaptured.value = true;
      }

      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      print("Error al tomar la foto: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
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
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  capturedImage = null;
                });
                Navigator.of(context).pop();
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
