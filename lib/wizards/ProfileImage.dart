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
  File? _image;  // Cambiado para una sola imagen
  final ImagePicker _imagePicker = ImagePicker(); // Definición de _imagePicker

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _requestCameraPermission().then((_) {
      return _initializeCamera();
    });
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  Future<void> _showImagePreview() async {
    if (_image != null) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(_image!), // Mostrar la única imagen
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _image = null; // Elimina la imagen
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Eliminar imagen"),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _pickImage() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tomese una foto de perfil', style: MyTextStyles.drawerButtonTextStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Cierra el cuadro de diálogo
                  final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
                  _processImage(image);
                },
                child: Text('Tomar Foto'),
              ),
            ],
          ),
        );
      },
    );
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

  bool isStep3Valid() {
    return capturedImage != null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Paso 3: Saque una foto de perfil sin gafas ni gorra",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: 400,
          width: double.maxFinite,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => _pickImage(),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xA3C9D2D2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _image == null
                      ? Center(
                          child: Icon(
                            Icons.cloud_upload,
                            size: 48,
                            color: Color(0xA3C9D2D2),
                          ),
                        )
                      : Image.file(
                          _image!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ],
          ),
        ),
        if (!isStep3Valid())
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Saca una foto antes de continuar.',
              style: TextStyle(color: Color(0xFF830A09)),
            ),
          ),
      ],
    );
  }

  void _processImage(XFile? image) {
    if (image != null) {
      setState(() {
        _image = File(image.path); // Solo guarda una imagen
      });

      widget.onImageSelected(Step3FormData(imagePath: image.path));
      widget.isImageCaptured.value = true;
    }
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

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}
